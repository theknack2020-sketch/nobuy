import AppIntents
import SwiftData
import WidgetKit

// MARK: - Answering today, from anywhere
//
// Run from Siri, a Shortcut, and — new in v2.0.0 — a button inside the Home Screen widget.
//
// Two things this file must not lose:
//
//   · **It opens the SAME store the app opens** (`NoBuyStore.makeContainer`). Building its own
//     default-location container — as it did until v2.0.0 — writes the answer into a file the
//     app stopped reading the moment the records moved into the App Group. It would have
//     succeeded, said "logged", and shown nothing.
//   · **It reloads the timelines.** A widget that writes a day and then keeps drawing the old
//     one teaches people not to trust it.

struct MarkNoBuyIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Today as No-Buy"
    static let description = IntentDescription("Mark today as a no-spend day in NoBuy")
    static let openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        try DayAnswerWriter.write(didSpend: false)
        return .result(dialog: "Today is logged as a no-spend day.")
    }
}

// MARK: - The other answer
//
// The widget offers BOTH answers. Offering only the flattering one turns the record into a
// story: someone who spent taps nothing, the day stays open, and the streak survives on silence.

struct MarkSpentIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Today as Spent"
    static let description = IntentDescription("Record that today included an unnecessary purchase")
    static let openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        try DayAnswerWriter.write(didSpend: true)
        return .result(dialog: "Today is recorded as a spend day.")
    }
}

// MARK: - The one writer

enum DayAnswerWriter {
    static func write(didSpend: Bool) throws {
        // `creating: false` — this runs in the widget's process as often as in the app's, and a
        // process that cannot see the record must refuse rather than start a second, empty one.
        let container = try NoBuyStore.makeContainer(creating: false)
        let context = ModelContext(container)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        let descriptor = FetchDescriptor<DayRecord>(predicate: #Predicate { record in
            record.date >= today
        })
        let existing = try context.fetch(descriptor)
        let todayRecord = existing.first { calendar.isDate($0.date, inSameDayAs: today) }

        if let record = todayRecord {
            record.didSpend = didSpend
            record.isMandatoryOnly = false
        } else {
            context.insert(DayRecord(date: today, didSpend: didSpend))
        }
        try context.save()

        WidgetCenter.shared.reloadAllTimelines()
    }
}
