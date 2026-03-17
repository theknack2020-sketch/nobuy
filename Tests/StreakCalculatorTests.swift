import Testing
import Foundation
@testable import NoBuy

@Suite("StreakCalculator")
struct StreakCalculatorTests {
    private func makeRecord(daysAgo: Int, didSpend: Bool = false, mandatoryOnly: Bool = false) -> DayRecord {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        return DayRecord(date: date, didSpend: didSpend, isMandatoryOnly: mandatoryOnly)
    }

    @Test("Empty records returns zero streak")
    func emptyRecords() {
        let info = StreakCalculator.calculate(from: [])
        #expect(info.currentStreak == 0)
        #expect(info.longestStreak == 0)
    }

    @Test("Single no-buy day today")
    func singleNoBuyToday() {
        let records = [makeRecord(daysAgo: 0)]
        let info = StreakCalculator.calculate(from: records)
        #expect(info.currentStreak == 1)
        #expect(info.longestStreak == 1)
    }

    @Test("Consecutive no-buy days")
    func consecutiveDays() {
        let records = [
            makeRecord(daysAgo: 0),
            makeRecord(daysAgo: 1),
            makeRecord(daysAgo: 2),
        ]
        let info = StreakCalculator.calculate(from: records)
        #expect(info.currentStreak == 3)
        #expect(info.longestStreak == 3)
    }

    @Test("Streak broken by spend day")
    func brokenStreak() {
        let records = [
            makeRecord(daysAgo: 0),
            makeRecord(daysAgo: 1, didSpend: true), // breaks streak
            makeRecord(daysAgo: 2),
            makeRecord(daysAgo: 3),
        ]
        let info = StreakCalculator.calculate(from: records)
        #expect(info.currentStreak == 1)
        #expect(info.longestStreak == 2)
    }

    @Test("Mandatory-only spending doesn't break streak")
    func mandatoryKeepsStreak() {
        let records = [
            makeRecord(daysAgo: 0),
            makeRecord(daysAgo: 1, didSpend: true, mandatoryOnly: true), // mandatory = no-buy
            makeRecord(daysAgo: 2),
        ]
        let info = StreakCalculator.calculate(from: records)
        #expect(info.currentStreak == 3)
    }

    @Test("No-buy days this month count")
    func monthlyCount() {
        let records = [
            makeRecord(daysAgo: 0),
            makeRecord(daysAgo: 1),
            makeRecord(daysAgo: 2, didSpend: true),
        ]
        let info = StreakCalculator.calculate(from: records)
        #expect(info.noBuyDaysThisMonth >= 2)
    }
}
