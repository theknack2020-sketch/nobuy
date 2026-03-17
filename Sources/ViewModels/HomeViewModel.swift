import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class HomeViewModel {
    var todayRecord: DayRecord?
    var streakInfo: StreakInfo = .empty
    var showSpendOptions = false

    var isTodayNoBuy: Bool {
        todayRecord?.isNoBuyDay ?? false
    }

    var isTodayRecorded: Bool {
        todayRecord != nil
    }

    var todayStatusText: String {
        guard let record = todayRecord else {
            return L10n.noRecordYet
        }
        if record.isNoBuyDay {
            return L10n.noBuyToday
        } else {
            return L10n.spentToday
        }
    }

    func loadToday(records: [DayRecord]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        todayRecord = records.first { calendar.startOfDay(for: $0.date) == today }
        streakInfo = StreakCalculator.calculate(from: records)
    }

    func markNoBuy(context: ModelContext, allRecords: [DayRecord]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        if let existing = todayRecord {
            existing.didSpend = false
            existing.isMandatoryOnly = false
        } else {
            let record = DayRecord(date: today, didSpend: false)
            context.insert(record)
            todayRecord = record
        }

        try? context.save()
        HapticManager.noBuySuccess()

        // Recalculate streak
        var updated = allRecords.filter { calendar.startOfDay(for: $0.date) != today }
        if let current = todayRecord { updated.append(current) }
        streakInfo = StreakCalculator.calculate(from: updated)

        // Streak notification
        let streak = streakInfo.currentStreak
        Task {
            let manager = NotificationManager()
            await manager.scheduleStreakNotification(streak: streak)
        }
    }

    func markSpent(context: ModelContext, mandatoryOnly: Bool, allRecords: [DayRecord]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        if let existing = todayRecord {
            existing.didSpend = true
            existing.isMandatoryOnly = mandatoryOnly
        } else {
            let record = DayRecord(date: today, didSpend: true, isMandatoryOnly: mandatoryOnly)
            context.insert(record)
            todayRecord = record
        }

        try? context.save()
        HapticManager.toggle()

        // Recalculate streak
        var updated = allRecords.filter { calendar.startOfDay(for: $0.date) != today }
        if let current = todayRecord { updated.append(current) }
        streakInfo = StreakCalculator.calculate(from: updated)
    }

    func requestNotificationPermission() {
        Task {
            let manager = NotificationManager()
            await manager.requestAuthorization()
        }
    }
}
