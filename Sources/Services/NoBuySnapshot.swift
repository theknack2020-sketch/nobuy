import Foundation
import SwiftData

// MARK: - What a widget knows
//
// Lives in the app's source tree rather than the widget's, for one reason: a test module can
// only compile a file whose dependencies it can see, and `@testable import NoBuy` has to be in
// the file itself. Kept in `Widget/`, this reading would be the one piece of the release that
// nothing could test. The app compiles a small value type it does not draw; the widget and the
// tests both get the REAL one instead of a copy that drifts.
//
// One value type, read once per timeline entry. The widget never holds a `ModelContext` open,
// never observes, and never computes twice — a widget process is short-lived and budgeted, and
// everything drawn has to survive being rendered minutes after it was read.
//
// Every remainder in here is ROUNDED and rendered with a tilde ("~tonight", "~2 h left"). A
// widget cannot tick, so a value that looks precise is a value that will be wrong within the
// hour. The design's rule, kept in the data rather than in the views, so no view can forget it.

struct NoBuySnapshot: Equatable {
    var streak: Int
    var today: DayTruth
    /// Oldest first, ending with today.
    var lastSevenDays: [DayTruth]
    /// The nearest item still on hold, phrased as it is drawn.
    var nearestWait: String?
    /// Nothing has ever been answered — a fresh install, where "0 days" is not a design.
    var hasNoRecords: Bool
    /// Rounded time left in the day, e.g. "~2 h left". Nil once the day is answered.
    var remainderOfDay: String?

    var isAnswered: Bool { today != .notYet }

    /// "1 day", not "1 days". A widget is four words long; one of them being wrong is a quarter
    /// of the surface.
    var dayWord: String { streak == 1 ? "day" : "days" }

    static let placeholder = NoBuySnapshot(
        streak: 23,
        today: .notYet,
        lastSevenDays: [.kept, .kept, .spent, .kept, .frozen, .kept, .notYet],
        nearestWait: "grinder off hold ~tonight",
        hasNoRecords: false,
        remainderOfDay: "~2 h left"
    )

    static let empty = NoBuySnapshot(
        streak: 0,
        today: .notYet,
        lastSevenDays: Array(repeating: .notYet, count: 7),
        nearestWait: nil,
        hasNoRecords: true,
        remainderOfDay: nil
    )
}

// MARK: - Reading it

enum NoBuySnapshotReader {
    static func read(now: Date = .now) -> NoBuySnapshot {
        // Never creates: a widget rendering before the app has settled the store shows its
        // honest empty state, and the record it cannot see stays exactly where it is.
        guard let container = try? NoBuyStore.makeContainer(creating: false) else { return .empty }
        let context = ModelContext(container)
        let records = (try? context.fetch(FetchDescriptor<DayRecord>())) ?? []
        return snapshot(from: records, waits: activeWaits(), now: now)
    }

    /// Pure, so the reading can be tested without a store or a widget host.
    static func snapshot(from records: [DayRecord], waits: [WaitingItem], now: Date) -> NoBuySnapshot {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        guard !records.isEmpty else { return .empty }

        let byDay = Dictionary(
            records.map { (calendar.startOfDay(for: $0.date), $0) },
            uniquingKeysWith: { first, second in first.createdAt >= second.createdAt ? first : second }
        )

        let todayTruth = byDay[today].map(truth(of:)) ?? .notYet
        let week: [DayTruth] = (0 ..< 7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return byDay[day].map(truth(of:)) ?? .notYet
        }

        return NoBuySnapshot(
            streak: StreakCalculator.calculate(from: records).currentStreak,
            today: todayTruth,
            lastSevenDays: week,
            nearestWait: nearestWaitPhrase(waits, now: now),
            hasNoRecords: false,
            remainderOfDay: todayTruth == .notYet ? remainder(until: endOfDay(after: now), from: now) : nil
        )
    }

    static func truth(of record: DayRecord) -> DayTruth {
        if record.isFrozen { return .frozen }
        if record.isMandatoryOnly { return .mandatoryOnly }
        return record.didSpend ? .spent : .kept
    }

    // MARK: - Waits

    private static func activeWaits() -> [WaitingItem] {
        guard let data = SharedDefaults.data(forKey: "waitingListItems"),
              let items = try? JSONDecoder().decode([WaitingItem].self, from: data)
        else { return [] }
        return items.filter { !$0.isResolved }
    }

    static func nearestWaitPhrase(_ waits: [WaitingItem], now: Date) -> String? {
        guard let next = waits
            .filter({ !$0.isResolved })
            .min(by: { $0.reminderDate < $1.reminderDate })
        else { return nil }
        return "\(next.name) off hold \(coarseWhen(next.reminderDate, from: now))"
    }

    // MARK: - Rounded time
    //
    // Three grains, coarsening with distance, because a widget rendered an hour ago must still
    // be telling the truth: "~soon" under an hour, "~N h" within the day, "~tonight" / "~tomorrow"
    // beyond it. Nothing here ever prints a minute.

    /// Every day comparison is made against the PASSED-IN `now`, never against the wall clock.
    /// The first draft used `isDateInToday` / `isDateInTomorrow`, which silently ignore the
    /// parameter and ask the real calendar instead — correct in production by coincidence, and
    /// wrong the moment a timeline entry is rendered for a future date, which is exactly what
    /// `getTimeline` does for every entry after the first.
    static func coarseWhen(_ date: Date, from now: Date) -> String {
        let calendar = Calendar.current
        if date <= now { return "now" }
        let hours = date.timeIntervalSince(now) / 3600
        if hours < 1 { return "~soon" }
        if calendar.isDate(date, inSameDayAs: now) { return hours < 6 ? "~in \(Int(hours)) h" : "~tonight" }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) { return "~tomorrow" }
        return "~\(Int(hours / 24)) days"
    }

    static func remainder(until end: Date, from now: Date) -> String? {
        let seconds = end.timeIntervalSince(now)
        guard seconds > 0 else { return nil }
        let hours = Int(seconds / 3600)
        if hours < 1 { return "~under an hour left" }
        return "~\(hours) h left"
    }

    static func endOfDay(after now: Date) -> Date {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: 1, to: start) ?? now
    }
}
