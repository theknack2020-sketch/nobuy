import Foundation
import Observation
import os

@Observable
@MainActor
final class AchievementManager {
    static let shared = AchievementManager()

    private(set) var achievements: [Achievement] = Achievement.all
    private(set) var newlyUnlocked: Achievement?
    private(set) var lastError: String?

    private let storageKey = "unlockedAchievements"

    private init() {
        loadUnlocked()
    }

    func checkAchievements(currentStreak: Int, totalNoBuyDays: Int, records: [DayRecord]) {
        var hasNew = false
        for i in achievements.indices {
            guard !achievements[i].isUnlocked else { continue }
            var shouldUnlock = false
            if let required = achievements[i].requiredStreak, currentStreak >= required {
                shouldUnlock = true
            }
            if let required = achievements[i].requiredNoBuyDays, totalNoBuyDays >= required {
                shouldUnlock = true
            }
            if achievements[i].id == "perfect_month" {
                shouldUnlock = checkPerfectMonth(records: records)
            }
            if shouldUnlock {
                achievements[i].isUnlocked = true
                achievements[i].unlockedDate = .now
                if !hasNew {
                    newlyUnlocked = achievements[i]
                    hasNew = true
                }
            }
        }
        saveUnlocked()
    }

    func clearNewlyUnlocked() {
        newlyUnlocked = nil
    }

    func dismissError() {
        lastError = nil
    }

    #if DEBUG
    /// Reset all achievements to locked state — for testing only
    func resetForTesting() {
        achievements = Achievement.all
        newlyUnlocked = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
    #endif

    private func checkPerfectMonth(records: [DayRecord]) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else { return false }
        let daysSoFar = calendar.dateComponents([.day], from: monthStart, to: today).day! + 1
        guard daysSoFar >= 28 else { return false } // At least 28 days in the month
        let noBuyDates = Set(records.filter { $0.isNoBuyDay }.map { calendar.startOfDay(for: $0.date) })
        for offset in 0..<daysSoFar {
            guard let date = calendar.date(byAdding: .day, value: offset, to: monthStart) else { return false }
            if !noBuyDates.contains(date) { return false }
        }
        return true
    }

    private func loadUnlocked() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let ids = try JSONDecoder().decode([String: Date].self, from: data)
            for i in achievements.indices {
                if let date = ids[achievements[i].id] {
                    achievements[i].isUnlocked = true
                    achievements[i].unlockedDate = date
                }
            }
        } catch {
            AppLogger.data.error("Failed to decode achievements: \(error.localizedDescription)")
            lastError = "Couldn't load your achievements. They may reset."
        }
    }

    private func saveUnlocked() {
        let ids = Dictionary(uniqueKeysWithValues: achievements.filter { $0.isUnlocked }.compactMap { a -> (String, Date)? in
            guard let date = a.unlockedDate else { return nil }
            return (a.id, date)
        })
        do {
            let data = try JSONEncoder().encode(ids)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            AppLogger.data.error("Failed to save achievements: \(error.localizedDescription)")
            lastError = "Couldn't save your achievement progress."
        }
    }
}
