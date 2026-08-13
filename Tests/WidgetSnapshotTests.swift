import Foundation
import Testing
@testable import NoBuy

/// A widget is rendered once and then read for minutes, sometimes hours. Everything it prints
/// has to be true for the whole time it is on screen — which is why nothing here is precise:
/// every remainder is rounded and carries a tilde, so a stale render cannot lie.
///
/// The other half is the empty case. "0 days" on a fresh install is not a design; the reading
/// has to be able to say "nothing recorded yet" rather than "zero", and this pins that too.
@Suite("Widget reading")
struct WidgetSnapshotTests {
    private let now = Date(timeIntervalSince1970: 1_786_500_000) // fixed instant, no wall clock

    private func record(daysAgo: Int, didSpend: Bool = false, mandatoryOnly: Bool = false, frozen: Bool = false) -> DayRecord {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: now)!
        return DayRecord(date: date, didSpend: didSpend, isMandatoryOnly: mandatoryOnly, isFrozen: frozen)
    }

    @Test("No records reads as empty, never as zero days")
    func emptyIsNotZero() {
        let reading = NoBuySnapshotReader.snapshot(from: [], waits: [], now: now)
        #expect(reading.hasNoRecords)
        #expect(reading.streak == 0)
        #expect(reading.remainderOfDay == nil)
    }

    @Test("Today's truth and the week come back in drawing order")
    func weekIsOldestFirst() {
        let reading = NoBuySnapshotReader.snapshot(
            from: [record(daysAgo: 0), record(daysAgo: 1, didSpend: true), record(daysAgo: 6, frozen: true)],
            waits: [],
            now: now
        )
        #expect(reading.hasNoRecords == false)
        #expect(reading.lastSevenDays.count == 7)
        #expect(reading.lastSevenDays.first == .frozen) // six days ago
        #expect(reading.lastSevenDays.last == .kept) // today
        #expect(reading.lastSevenDays[5] == .spent) // yesterday
        #expect(reading.today == .kept)
        #expect(reading.isAnswered)
    }

    @Test("An unanswered day carries a rounded remainder; an answered one carries none")
    func remainderOnlyWhileOpen() {
        let open = NoBuySnapshotReader.snapshot(from: [record(daysAgo: 3)], waits: [], now: now)
        #expect(open.today == .notYet)
        #expect(open.remainderOfDay?.hasPrefix("~") == true)

        let answered = NoBuySnapshotReader.snapshot(from: [record(daysAgo: 0)], waits: [], now: now)
        #expect(answered.remainderOfDay == nil)
    }

    @Test("One day is a day, not days")
    func singularCountReads() {
        let one = NoBuySnapshotReader.snapshot(from: [record(daysAgo: 0)], waits: [], now: now)
        #expect(one.streak == 1)
        #expect(one.dayWord == "day")

        let two = NoBuySnapshotReader.snapshot(from: [record(daysAgo: 0), record(daysAgo: 1)], waits: [], now: now)
        #expect(two.streak == 2)
        #expect(two.dayWord == "days")
    }

    @Test("Every rounded time is coarse enough to survive a stale render")
    func coarseTimeNeverPrintsMinutes() {
        let cases: [(TimeInterval, String)] = [
            (60 * 20, "~soon"),
            (3600 * 3, "~in 3 h"),
        ]
        for (offset, expected) in cases {
            let phrase = NoBuySnapshotReader.coarseWhen(now.addingTimeInterval(offset), from: now)
            #expect(phrase == expected, "offset \(offset) read as \(phrase)")
        }
        // Already due reads as a fact, not a negative remainder.
        #expect(NoBuySnapshotReader.coarseWhen(now.addingTimeInterval(-60), from: now) == "now")
        // Nothing anywhere prints a minute value.
        for offset in stride(from: 60.0, to: 3600 * 72, by: 3600) {
            let phrase = NoBuySnapshotReader.coarseWhen(now.addingTimeInterval(offset), from: now)
            #expect(phrase.contains(":") == false)
            #expect(phrase.contains("min") == false)
        }
    }

    @Test("The nearest wait is the one that comes off hold first")
    func nearestWaitWins() {
        var soon = WaitingItem(name: "grinder", reminderHours: 2)
        var later = WaitingItem(name: "jacket", reminderHours: 40)
        soon.reminderDate = now.addingTimeInterval(3600 * 2)
        later.reminderDate = now.addingTimeInterval(3600 * 40)

        let phrase = NoBuySnapshotReader.nearestWaitPhrase([later, soon], now: now)
        #expect(phrase?.hasPrefix("grinder off hold") == true)
    }

    @Test("A resolved item is not on hold and never fills the slot")
    func resolvedWaitsAreIgnored() {
        var done = WaitingItem(name: "grinder", reminderHours: 2)
        done.reminderDate = now.addingTimeInterval(3600 * 2)
        done.isResolved = true
        #expect(NoBuySnapshotReader.nearestWaitPhrase([done], now: now) == nil)
    }

    @Test("Two records for the same day resolve to the newer one")
    func duplicateDaysDoNotFlicker() {
        let older = record(daysAgo: 0, didSpend: true)
        let newer = record(daysAgo: 0, didSpend: false)
        // `createdAt` is stamped at init, so `newer` is genuinely the later write.
        #expect(newer.createdAt >= older.createdAt)

        let reading = NoBuySnapshotReader.snapshot(from: [older, newer], waits: [], now: now)
        #expect(reading.today == .kept)
    }
}
