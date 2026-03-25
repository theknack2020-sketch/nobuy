import Testing
import Foundation
@testable import NoBuy

@Suite("StatsViewModel")
struct StatsViewModelTests {

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

    // MARK: - Monthly Data

    @Test("Monthly data has up to 6 entries")
    @MainActor
    func monthlyDataCount() {
        let vm = StatsViewModel()
        var records: [DayRecord] = []
        for i in 0..<90 {
            records.append(Self.makeRecord(daysAgo: i))
        }
        vm.compute(from: records, dailySpendingEstimate: 50)
        #expect(vm.monthlyData.count <= 6)
        #expect(vm.monthlyData.count >= 1)
    }

    @Test("Monthly data reflects no-buy counts correctly")
    @MainActor
    func monthlyDataNoBuyCounts() {
        let vm = StatsViewModel()
        // All days are no-buy (didSpend: false)
        var records: [DayRecord] = []
        for i in 0..<5 {
            records.append(Self.makeRecord(daysAgo: i))
        }
        vm.compute(from: records, dailySpendingEstimate: 0)

        // The most recent month entry should have these no-buy days
        guard let currentMonth = vm.monthlyData.last else {
            #expect(Bool(false), "Should have monthly data")
            return
        }
        #expect(currentMonth.noBuyCount >= 5)
        #expect(currentMonth.percentage > 0)
    }

    @Test("Monthly data with empty records produces empty or zero-count data")
    @MainActor
    func monthlyDataEmpty() {
        let vm = StatsViewModel()
        vm.compute(from: [], dailySpendingEstimate: 50)
        // Monthly data still generates month entries but with 0 counts
        for month in vm.monthlyData {
            #expect(month.noBuyCount == 0)
        }
    }

    // MARK: - Weekday Distribution

    @Test("Weekday distribution has 7 entries")
    @MainActor
    func weekdayDistributionCount() {
        let vm = StatsViewModel()
        var records: [DayRecord] = []
        for i in 0..<14 {
            records.append(Self.makeRecord(daysAgo: i))
        }
        vm.compute(from: records, dailySpendingEstimate: 0)
        #expect(vm.weekdayData.count == 7)
    }

    @Test("Weekday data starts from Monday (weekday=1)")
    @MainActor
    func weekdayStartsMonday() {
        let vm = StatsViewModel()
        vm.compute(from: [Self.makeRecord(daysAgo: 0)], dailySpendingEstimate: 0)
        #expect(vm.weekdayData.first?.weekday == 1)
        #expect(vm.weekdayData.last?.weekday == 7)
    }

    @Test("Weekday percentages are valid")
    @MainActor
    func weekdayPercentages() {
        let vm = StatsViewModel()
        var records: [DayRecord] = []
        for i in 0..<21 {
            // Alternate no-buy and spend days
            records.append(Self.makeRecord(daysAgo: i, didSpend: i % 2 == 1))
        }
        vm.compute(from: records, dailySpendingEstimate: 0)

        for wd in vm.weekdayData {
            #expect(wd.percentage >= 0)
            #expect(wd.percentage <= 100)
        }
    }

    // MARK: - Trend Calculation

    @Test("Trend comparison is computed")
    @MainActor
    func trendExists() {
        let vm = StatsViewModel()
        var records: [DayRecord] = []
        for i in 0..<40 {
            records.append(Self.makeRecord(daysAgo: i))
        }
        vm.compute(from: records, dailySpendingEstimate: 50)
        #expect(vm.trendComparison != nil)
    }

    @Test("Trend shows improvement when this month is better")
    @MainActor
    func trendImproving() {
        let vm = StatsViewModel()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // This month: all no-buy days
        var records: [DayRecord] = []
        let daysSoFar = (calendar.dateComponents([.day], from: today.startOfMonth, to: today).day ?? 0) + 1
        for i in 0..<daysSoFar {
            records.append(Self.makeRecord(daysAgo: i))
        }

        // Last month: all spend days
        guard let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: today.startOfMonth) else { return }
        let lastMonthDays = calendar.range(of: .day, in: .month, for: lastMonthStart)?.count ?? 30
        for i in 0..<lastMonthDays {
            guard let date = calendar.date(byAdding: .day, value: i, to: lastMonthStart) else { continue }
            records.append(DayRecord(date: date, didSpend: true))
        }

        vm.compute(from: records, dailySpendingEstimate: 50)

        if let trend = vm.trendComparison {
            #expect(trend.isImproving == true)
            #expect(trend.delta > 0)
            #expect(trend.thisMonthPercentage > trend.lastMonthPercentage)
        }
    }

    @Test("Trend shows declining when last month was better")
    @MainActor
    func trendDeclining() {
        let vm = StatsViewModel()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // This month: all spend days
        var records: [DayRecord] = []
        let daysSoFar = (calendar.dateComponents([.day], from: today.startOfMonth, to: today).day ?? 0) + 1
        for i in 0..<daysSoFar {
            records.append(Self.makeRecord(daysAgo: i, didSpend: true))
        }

        // Last month: all no-buy days
        guard let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: today.startOfMonth) else { return }
        let lastMonthDays = calendar.range(of: .day, in: .month, for: lastMonthStart)?.count ?? 30
        for i in 0..<lastMonthDays {
            guard let date = calendar.date(byAdding: .day, value: i, to: lastMonthStart) else { continue }
            records.append(DayRecord(date: date, didSpend: false))
        }

        vm.compute(from: records, dailySpendingEstimate: 50)

        if let trend = vm.trendComparison {
            #expect(trend.isImproving == false)
            #expect(trend.delta < 0)
        }
    }

    // MARK: - Overall Stats

    @Test("totalNoBuyDays counts correctly")
    @MainActor
    func totalNoBuyDays() {
        let vm = StatsViewModel()
        let records = [
            Self.makeRecord(daysAgo: 0),              // no-buy
            Self.makeRecord(daysAgo: 1, didSpend: true), // spent
            Self.makeRecord(daysAgo: 2),              // no-buy
            Self.makeRecord(daysAgo: 3, didSpend: true, isMandatoryOnly: true), // mandatory = no-buy
        ]
        vm.compute(from: records, dailySpendingEstimate: 0)
        #expect(vm.totalNoBuyDays == 3) // days 0, 2, 3
    }

    @Test("estimatedSavings in stats uses total no-buy days")
    @MainActor
    func estimatedSavingsStats() {
        let vm = StatsViewModel()
        var records: [DayRecord] = []
        for i in 0..<10 {
            records.append(Self.makeRecord(daysAgo: i))
        }
        vm.compute(from: records, dailySpendingEstimate: 100)
        #expect(vm.estimatedSavings == Double(vm.totalNoBuyDays) * 100)
    }

    @Test("Streaks are calculated from stats compute")
    @MainActor
    func streaksFromCompute() {
        let vm = StatsViewModel()
        var records: [DayRecord] = []
        for i in 0..<5 {
            records.append(Self.makeRecord(daysAgo: i))
        }
        vm.compute(from: records, dailySpendingEstimate: 0)
        #expect(vm.currentStreak == 5)
        #expect(vm.longestStreak == 5)
    }

    @Test("Heatmap contains entries")
    @MainActor
    func heatmapPopulated() {
        let vm = StatsViewModel()
        var records: [DayRecord] = []
        for i in 0..<30 {
            records.append(Self.makeRecord(daysAgo: i))
        }
        vm.compute(from: records, dailySpendingEstimate: 0)
        #expect(vm.heatmapDays.count > 0)
    }

    @Test("Empty records produce zero stats")
    @MainActor
    func emptyRecords() {
        let vm = StatsViewModel()
        vm.compute(from: [], dailySpendingEstimate: 100)
        #expect(vm.totalNoBuyDays == 0)
        #expect(vm.currentStreak == 0)
        #expect(vm.longestStreak == 0)
        #expect(vm.estimatedSavings == 0)
    }
}
