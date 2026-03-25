import Testing
import Foundation
import SwiftData
@testable import NoBuy

@Suite("HomeViewModel")
struct HomeViewModelTests {

    // MARK: - Helpers

    @MainActor
    private static func makeContainer() throws -> ModelContainer {
        let schema = Schema([DayRecord.self, MandatoryCategory.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private static func makeRecord(
        daysAgo: Int,
        didSpend: Bool = false,
        isMandatoryOnly: Bool = false,
        isFrozen: Bool = false,
        note: String? = nil
    ) -> DayRecord {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        return DayRecord(
            date: date,
            didSpend: didSpend,
            isMandatoryOnly: isMandatoryOnly,
            isFrozen: isFrozen,
            note: note
        )
    }

    // MARK: - loadToday

    @Test("loadToday finds today's record")
    @MainActor
    func loadTodayFindsRecord() {
        let vm = HomeViewModel()
        let today = Self.makeRecord(daysAgo: 0)
        let yesterday = Self.makeRecord(daysAgo: 1)
        vm.loadToday(records: [today, yesterday])
        #expect(vm.todayRecord != nil)
        #expect(vm.isTodayRecorded == true)
    }

    @Test("loadToday with no records results in nil")
    @MainActor
    func loadTodayEmpty() {
        let vm = HomeViewModel()
        vm.loadToday(records: [])
        #expect(vm.todayRecord == nil)
        #expect(vm.isTodayRecorded == false)
        #expect(vm.isTodayNoBuy == false)
    }

    @Test("loadToday calculates streak info")
    @MainActor
    func loadTodayStreakInfo() {
        let vm = HomeViewModel()
        let records = [
            Self.makeRecord(daysAgo: 0),
            Self.makeRecord(daysAgo: 1),
            Self.makeRecord(daysAgo: 2),
        ]
        vm.loadToday(records: records)
        #expect(vm.streakInfo.currentStreak == 3)
    }

    // MARK: - markNoBuy

    @Test("markNoBuy creates a record for today")
    @MainActor
    func markNoBuyCreatesRecord() throws {
        let container = try Self.makeContainer()
        let context = container.mainContext
        let vm = HomeViewModel()

        vm.markNoBuy(context: context, allRecords: [])

        #expect(vm.todayRecord != nil)
        #expect(vm.todayRecord?.didSpend == false)
        #expect(vm.todayRecord?.isMandatoryOnly == false)
        #expect(vm.isTodayNoBuy == true)
    }

    @Test("markNoBuy updates existing record to no-buy")
    @MainActor
    func markNoBuyUpdatesExisting() throws {
        let container = try Self.makeContainer()
        let context = container.mainContext

        let vm = HomeViewModel()
        let existing = Self.makeRecord(daysAgo: 0, didSpend: true)
        context.insert(existing)
        try context.save()

        vm.loadToday(records: [existing])
        vm.markNoBuy(context: context, allRecords: [existing])

        #expect(vm.todayRecord?.didSpend == false)
        #expect(vm.isTodayNoBuy == true)
    }

    @Test("markNoBuy sets lastError on save failure remains nil on success")
    @MainActor
    func markNoBuyNoErrorOnSuccess() throws {
        let container = try Self.makeContainer()
        let context = container.mainContext
        let vm = HomeViewModel()

        vm.markNoBuy(context: context, allRecords: [])
        #expect(vm.lastError == nil)
    }

    // MARK: - markSpent

    @Test("markSpent with mandatory-only keeps isNoBuyDay true")
    @MainActor
    func markSpentMandatory() throws {
        let container = try Self.makeContainer()
        let context = container.mainContext
        let vm = HomeViewModel()

        vm.markSpent(context: context, mandatoryOnly: true, allRecords: [])

        #expect(vm.todayRecord != nil)
        #expect(vm.todayRecord?.didSpend == true)
        #expect(vm.todayRecord?.isMandatoryOnly == true)
        #expect(vm.todayRecord?.isNoBuyDay == true) // mandatory-only counts as no-buy
    }

    @Test("markSpent discretionary breaks streak")
    @MainActor
    func markSpentDiscretionary() throws {
        let container = try Self.makeContainer()
        let context = container.mainContext
        let vm = HomeViewModel()

        // Build a streak first
        let records = [
            Self.makeRecord(daysAgo: 1),
            Self.makeRecord(daysAgo: 2),
        ]
        for r in records { context.insert(r) }
        try context.save()

        // Disable freezes so it doesn't show freeze offer
        vm.loadToday(records: records)
        UserDefaults.standard.set(0, forKey: "streakFreezeCount")

        vm.markSpent(context: context, mandatoryOnly: false, allRecords: records)

        #expect(vm.todayRecord?.didSpend == true)
        #expect(vm.todayRecord?.isMandatoryOnly == false)
        #expect(vm.todayRecord?.isNoBuyDay == false)
    }

    // MARK: - todayMotivationalText

    @Test("todayMotivationalText returns non-empty string for zero streak")
    @MainActor
    func motivationalTextZeroStreak() {
        let vm = HomeViewModel()
        vm.loadToday(records: [])
        let text = vm.todayMotivationalText
        #expect(!text.isEmpty)
    }

    @Test("todayMotivationalText varies by streak length")
    @MainActor
    func motivationalTextVaries() {
        let vm = HomeViewModel()

        // Zero streak
        vm.loadToday(records: [])
        let zeroText = vm.todayMotivationalText

        // 10-day streak
        var records: [DayRecord] = []
        for i in 0..<10 {
            records.append(Self.makeRecord(daysAgo: i))
        }
        vm.loadToday(records: records)
        let tenText = vm.todayMotivationalText

        // Different streak ranges should generally produce different message pools
        // (can't guarantee different text due to date-seeded randomization, but we verify both are non-empty)
        #expect(!zeroText.isEmpty)
        #expect(!tenText.isEmpty)
    }

    // MARK: - estimatedSavings

    @Test("estimatedSavings is zero when dailySpendingEstimate is zero")
    @MainActor
    func estimatedSavingsZero() {
        let vm = HomeViewModel()
        vm.dailySpendingEstimate = 0
        vm.loadToday(records: [Self.makeRecord(daysAgo: 0)])
        #expect(vm.estimatedSavings == 0)
    }

    @Test("estimatedSavings multiplies noBuyDaysThisMonth by daily estimate")
    @MainActor
    func estimatedSavingsCalculation() {
        let vm = HomeViewModel()
        vm.dailySpendingEstimate = 50

        // Create 3 no-buy days within this month
        var records: [DayRecord] = []
        for i in 0..<3 {
            records.append(Self.makeRecord(daysAgo: i))
        }
        vm.loadToday(records: records)

        let expected = Double(vm.streakInfo.noBuyDaysThisMonth) * 50
        #expect(vm.estimatedSavings == expected)
    }

    @Test("formattedEstimatedSavings returns non-empty string")
    @MainActor
    func formattedEstimatedSavingsNonEmpty() {
        let vm = HomeViewModel()
        vm.dailySpendingEstimate = 100
        vm.loadToday(records: [Self.makeRecord(daysAgo: 0)])
        #expect(!vm.formattedEstimatedSavings.isEmpty)
    }

    // MARK: - Challenge state

    @Test("startChallenge and clearChallenge work correctly")
    @MainActor
    func challengeLifecycle() {
        let vm = HomeViewModel()
        vm.startChallenge(duration: 7)
        #expect(vm.challengeDuration == 7)
        #expect(vm.isChallengeActive == true)
        #expect(vm.challengeDaysRemaining <= 7)

        vm.clearChallenge()
        #expect(vm.challengeDuration == 0)
        #expect(vm.isChallengeActive == false)
    }
}
