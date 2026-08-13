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

    @Test("Unlogged today is pending, not broken — streak anchors on yesterday")
    func unloggedTodayKeepsStreakAlive() {
        let records = [
            makeRecord(daysAgo: 1),
            makeRecord(daysAgo: 2),
            makeRecord(daysAgo: 3),
        ]
        let info = StreakCalculator.calculate(from: records)
        #expect(info.currentStreak == 3)
    }

    @Test("A discretionary spend logged today still breaks the streak")
    func spendTodayBreaksStreak() {
        let records = [
            makeRecord(daysAgo: 0, didSpend: true),
            makeRecord(daysAgo: 1),
            makeRecord(daysAgo: 2),
        ]
        let info = StreakCalculator.calculate(from: records)
        #expect(info.currentStreak == 0)
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

// MARK: - Every run, kept (the M-09 graft)
//
// The measure carried over from the rejected Doorframe direction: an ended run is never
// deleted, truncated or zeroed. Stats draws these forever, so the computation behind them is
// pinned here — this is the product's answer to its largest churn risk, and a refactor that
// quietly drops a settled run would remove the answer without removing the promise.

@Suite("Every run, kept")
struct RunHistoryTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now))!
    }

    private func kept(_ offsets: [Int]) -> [DayRecord] {
        offsets.map { DayRecord(date: day($0), didSpend: false) }
    }

    @Test("No records means no runs")
    func emptyRecord() {
        #expect(StreakCalculator.allRuns(from: [], now: now).isEmpty)
    }

    @Test("Consecutive kept days form one run")
    func oneRun() {
        let runs = StreakCalculator.allRuns(from: kept([-2, -1, 0]), now: now)
        #expect(runs.count == 1)
        #expect(runs.first?.days == 3)
        #expect(runs.first?.isOpen == true)
    }

    @Test("A gap splits runs, and the older one settles")
    func twoRuns() {
        let runs = StreakCalculator.allRuns(from: kept([-10, -9, -8, -2, -1, 0]), now: now)
        #expect(runs.count == 2)
        // Newest first.
        #expect(runs[0].days == 3)
        #expect(runs[0].isOpen)
        #expect(runs[1].days == 3)
        #expect(!runs[1].isOpen, "an ended run must settle, not stay open")
    }

    /// The pending case: today is unanswered, so a run that reaches yesterday is still open —
    /// the same rule `calculate(from:)` uses to anchor the current streak.
    @Test("A run reaching yesterday is still open when today is unanswered")
    func pendingTodayKeepsRunOpen() {
        let runs = StreakCalculator.allRuns(from: kept([-2, -1]), now: now)
        #expect(runs.first?.isOpen == true)
    }

    @Test("A run that ended before yesterday is settled")
    func olderRunIsSettled() {
        let runs = StreakCalculator.allRuns(from: kept([-5, -4, -3]), now: now)
        #expect(runs.first?.isOpen == false)
    }

    /// Frozen and essentials-only days hold a run — the three truths that keep a streak.
    @Test("Frozen and essentials-only days keep the run unbroken")
    func mercyDaysHoldTheRun() {
        let records = [
            DayRecord(date: day(-3), didSpend: false),
            DayRecord(date: day(-2), didSpend: true, isMandatoryOnly: true),
            DayRecord(date: day(-1), didSpend: false, isFrozen: true),
            DayRecord(date: day(0), didSpend: false),
        ]
        let runs = StreakCalculator.allRuns(from: records, now: now)
        #expect(runs.count == 1, "an essentials-only or frozen day must not split the run")
        #expect(runs.first?.days == 4)
    }

    @Test("A spent day ends the run it interrupts")
    func spentDayEndsRun() {
        let records = kept([-4, -3]) + [DayRecord(date: day(-2), didSpend: true)] + kept([-1, 0])
        let runs = StreakCalculator.allRuns(from: records, now: now)
        #expect(runs.count == 2)
        #expect(runs.allSatisfy { $0.days == 2 })
    }
}
