import SwiftUI
import WidgetKit

// MARK: - The timeline
//
// The product is opened once a day, at night, to answer one question. This surface exists so
// that answer can be given without opening anything — which makes the widget the product's
// shortest path, not a decoration.
//
// The schedule is the design's: the quarter-hours, one entry at 21:30 (the same sentence as the
// evening reminder), and one at midnight, where the rollover swaps "answered" back to open.
// Nothing here counts down; every remainder is rounded and rendered with a tilde, so a render
// that is an hour stale still cannot lie.

struct NoBuyEntry: TimelineEntry {
    let date: Date
    let snapshot: NoBuySnapshot
}

struct NoBuyProvider: TimelineProvider {
    func placeholder(in _: Context) -> NoBuyEntry {
        NoBuyEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (NoBuyEntry) -> Void) {
        // The gallery preview must never show a stranger's real record.
        let snapshot = context.isPreview ? NoBuySnapshot.placeholder : NoBuySnapshotReader.read()
        completion(NoBuyEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<NoBuyEntry>) -> Void) {
        let now = Date.now
        let snapshot = NoBuySnapshotReader.read(now: now)
        let entries = Self.refreshDates(from: now).map { date in
            NoBuyEntry(date: date, snapshot: NoBuySnapshotReader.read(now: date))
        }
        let timeline = Timeline(
            entries: [NoBuyEntry(date: now, snapshot: snapshot)] + entries,
            policy: .after(NoBuySnapshotReader.endOfDay(after: now))
        )
        completion(timeline)
    }

    /// Quarter-hours for the next few hours, then the evening line, then the rollover.
    static func refreshDates(from now: Date) -> [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []

        var cursor = now
        for _ in 0 ..< 8 {
            guard let next = calendar.date(byAdding: .minute, value: 15, to: cursor) else { break }
            cursor = next
            dates.append(next)
        }

        if let evening = calendar.date(
            bySettingHour: 21, minute: 30, second: 0, of: now
        ), evening > now {
            dates.append(evening)
        }
        dates.append(NoBuySnapshotReader.endOfDay(after: now))

        return dates.sorted()
    }
}

// MARK: - The widgets

struct NoBuyHomeWidget: Widget {
    let kind = "NoBuyHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NoBuyProvider()) { entry in
            NoBuyHomeView(snapshot: entry.snapshot)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today")
        .description("Answer today's question without opening NoBuy.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NoBuyAccessoryWidget: Widget {
    let kind = "NoBuyAccessoryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NoBuyProvider()) { entry in
            NoBuyAccessoryView(snapshot: entry.snapshot)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Run")
        .description("The run and today's state, on the Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

@main
struct NoBuyWidgetBundle: WidgetBundle {
    var body: some Widget {
        NoBuyHomeWidget()
        NoBuyAccessoryWidget()
    }
}
