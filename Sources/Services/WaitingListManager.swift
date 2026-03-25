import Foundation
import Observation
import UserNotifications
import os

@Observable
@MainActor
final class WaitingListManager {
    static let shared = WaitingListManager()

    private(set) var items: [WaitingItem] = []
    private(set) var lastError: String?
    private let storageKey = "waitingListItems"

    private init() { load() }

    var activeItems: [WaitingItem] { items.filter { !$0.isResolved } }
    var resolvedItems: [WaitingItem] { items.filter { $0.isResolved } }
    var savedMoney: Double {
        items
            .filter { $0.isResolved && $0.didBuy == false }
            .compactMap(\.estimatedCost)
            .reduce(0, +)
    }
    var resistedCount: Int {
        items.filter { $0.isResolved && $0.didBuy == false }.count
    }

    func addItem(_ item: WaitingItem) {
        items.append(item)
        save()
        scheduleReminder(for: item)
    }

    func resolveItem(id: UUID, didBuy: Bool) {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            AppLogger.data.warning("Attempted to resolve non-existent waiting list item: \(id)")
            return
        }
        items[index].isResolved = true
        items[index].didBuy = didBuy
        save()
        cancelReminder(for: items[index])
    }

    func removeItem(id: UUID) {
        if let item = items.first(where: { $0.id == id }) {
            cancelReminder(for: item)
        }
        items.removeAll { $0.id == id }
        save()
    }

    func dismissError() {
        lastError = nil
    }

    private func scheduleReminder(for item: WaitingItem) {
        let content = UNMutableNotificationContent()
        content.title = "Do you still want it?"
        content.body = String(
            format: "The waiting period for %@ has ended. Do you still want to buy it?",
            item.name
        )
        content.sound = .default

        let interval = item.reminderDate.timeIntervalSinceNow
        guard interval > 0 else { return }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "waiting.\(item.id.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error {
                AppLogger.notification.error("Failed to schedule waiting list reminder: \(error.localizedDescription)")
                Task { @MainActor in
                    self?.lastError = "Couldn't set a reminder. You'll need to check back manually."
                }
            }
        }
    }

    private func cancelReminder(for item: WaitingItem) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["waiting.\(item.id.uuidString)"])
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([WaitingItem].self, from: data)
            items = decoded
        } catch {
            AppLogger.data.error("Failed to decode waiting list: \(error.localizedDescription)")
            lastError = "Couldn't load your waiting list. It may have been reset."
            items = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
            lastError = nil
        } catch {
            AppLogger.data.error("Failed to save waiting list: \(error.localizedDescription)")
            lastError = "Couldn't save your waiting list changes."
        }
    }
}
