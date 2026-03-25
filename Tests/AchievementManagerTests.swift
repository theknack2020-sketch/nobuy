import Testing
import Foundation
@testable import NoBuy

@Suite("AchievementManager")
struct AchievementManagerTests {

    // MARK: - Helpers

    private static func makeRecord(
        daysAgo: Int,
        didSpend: Bool = false,
        isMandatoryOnly: Bool = false,
        isFrozen: Bool = false
    ) -> DayRecord {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        return DayRecord(
            date: date,
            didSpend: didSpend,
            isMandatoryOnly: isMandatoryOnly,
            isFrozen: isFrozen
        )
    }

    /// Resets all achievements to locked state and clears persisted data
    @MainActor
    private static func resetManager() {
        AchievementManager.shared.resetForTesting()
    }

    // MARK: - Unlock Logic

    @Test("First day achievement unlocks at streak 1")
    @MainActor
    func firstDayUnlock() {
        Self.resetManager()
        let manager = AchievementManager.shared

        let records = [Self.makeRecord(daysAgo: 0)]
        manager.checkAchievements(currentStreak: 1, totalNoBuyDays: 1, records: records)

        let firstDay = manager.achievements.first { $0.id == "first_day" }
        #expect(firstDay?.isUnlocked == true)
    }

    @Test("Streak-based achievements unlock at correct thresholds")
    @MainActor
    func streakAchievements() {
        Self.resetManager()
        let manager = AchievementManager.shared

        // Build 7-day streak records
        var records: [DayRecord] = []
        for i in 0..<7 {
            records.append(Self.makeRecord(daysAgo: i))
        }

        manager.checkAchievements(currentStreak: 7, totalNoBuyDays: 7, records: records)

        let streak3 = manager.achievements.first { $0.id == "streak_3" }
        let streak7 = manager.achievements.first { $0.id == "streak_7" }
        let streak14 = manager.achievements.first { $0.id == "streak_14" }

        #expect(streak3?.isUnlocked == true)
        #expect(streak7?.isUnlocked == true)
        #expect(streak14?.isUnlocked == false) // 7 < 14
    }

    @Test("Total no-buy day achievements unlock correctly")
    @MainActor
    func totalDayAchievements() {
        Self.resetManager()
        let manager = AchievementManager.shared

        // 30 total no-buy days, not necessarily consecutive
        var records: [DayRecord] = []
        for i in 0..<30 {
            records.append(Self.makeRecord(daysAgo: i))
        }

        manager.checkAchievements(currentStreak: 5, totalNoBuyDays: 30, records: records)

        let total30 = manager.achievements.first { $0.id == "total_30" }
        let total100 = manager.achievements.first { $0.id == "total_100" }

        #expect(total30?.isUnlocked == true)
        #expect(total100?.isUnlocked == false) // 30 < 100
    }

    @Test("newlyUnlocked is set on first unlock and cleared correctly")
    @MainActor
    func newlyUnlockedLifecycle() {
        Self.resetManager()
        let manager = AchievementManager.shared

        let records = [Self.makeRecord(daysAgo: 0)]
        manager.checkAchievements(currentStreak: 1, totalNoBuyDays: 1, records: records)

        #expect(manager.newlyUnlocked != nil)
        #expect(manager.newlyUnlocked?.id == "first_day")

        manager.clearNewlyUnlocked()
        #expect(manager.newlyUnlocked == nil)
    }

    @Test("Already-unlocked achievements don't re-trigger newlyUnlocked")
    @MainActor
    func noDoubleUnlock() {
        Self.resetManager()
        let manager = AchievementManager.shared

        let records = [Self.makeRecord(daysAgo: 0)]

        // First call — unlocks
        manager.checkAchievements(currentStreak: 1, totalNoBuyDays: 1, records: records)
        manager.clearNewlyUnlocked()

        // Second call — same conditions, nothing new
        manager.checkAchievements(currentStreak: 1, totalNoBuyDays: 1, records: records)
        #expect(manager.newlyUnlocked == nil)
    }

    // MARK: - Persistence

    @Test("Unlocked achievements persist across manager reloads via UserDefaults")
    @MainActor
    func persistence() {
        Self.resetManager()
        let manager = AchievementManager.shared

        let records = [Self.makeRecord(daysAgo: 0)]
        manager.checkAchievements(currentStreak: 1, totalNoBuyDays: 1, records: records)

        let firstDay = manager.achievements.first { $0.id == "first_day" }
        #expect(firstDay?.isUnlocked == true)

        // Verify UserDefaults has the data
        let data = UserDefaults.standard.data(forKey: "unlockedAchievements")
        #expect(data != nil)

        if let data = data, let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
            #expect(decoded["first_day"] != nil)
        }
    }

    // MARK: - Perfect Month

    @Test("Perfect month requires at least 28 days")
    @MainActor
    func perfectMonthRequires28Days() {
        Self.resetManager()
        let manager = AchievementManager.shared

        // Only 10 days — not enough
        var records: [DayRecord] = []
        for i in 0..<10 {
            records.append(Self.makeRecord(daysAgo: i))
        }

        manager.checkAchievements(currentStreak: 10, totalNoBuyDays: 10, records: records)

        let perfectMonth = manager.achievements.first { $0.id == "perfect_month" }
        #expect(perfectMonth?.isUnlocked == false)
    }

    @Test("Perfect month unlocks when every day of month is no-buy for 28+ days")
    @MainActor
    func perfectMonthUnlocks() {
        Self.resetManager()
        let manager = AchievementManager.shared

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else {
            return
        }
        let daysSoFar = (calendar.dateComponents([.day], from: monthStart, to: today).day ?? 0) + 1

        // We need 28+ days in the month so far
        guard daysSoFar >= 28 else {
            // Can't test perfect month early in the month — skip
            return
        }

        // Create a no-buy record for every day from month start to today
        var records: [DayRecord] = []
        for offset in 0..<daysSoFar {
            guard let date = calendar.date(byAdding: .day, value: offset, to: monthStart) else { continue }
            records.append(DayRecord(date: date, didSpend: false))
        }

        manager.checkAchievements(currentStreak: daysSoFar, totalNoBuyDays: daysSoFar, records: records)

        let perfectMonth = manager.achievements.first { $0.id == "perfect_month" }
        #expect(perfectMonth?.isUnlocked == true)
    }

    @Test("Perfect month fails if any day is missing")
    @MainActor
    func perfectMonthFailsWithGap() {
        Self.resetManager()
        let manager = AchievementManager.shared

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else {
            return
        }
        let daysSoFar = (calendar.dateComponents([.day], from: monthStart, to: today).day ?? 0) + 1
        guard daysSoFar >= 28 else { return }

        // Create records but skip day 5
        var records: [DayRecord] = []
        for offset in 0..<daysSoFar {
            if offset == 5 { continue } // gap
            guard let date = calendar.date(byAdding: .day, value: offset, to: monthStart) else { continue }
            records.append(DayRecord(date: date, didSpend: false))
        }

        manager.checkAchievements(currentStreak: 0, totalNoBuyDays: daysSoFar - 1, records: records)

        let perfectMonth = manager.achievements.first { $0.id == "perfect_month" }
        #expect(perfectMonth?.isUnlocked == false)
    }
}
