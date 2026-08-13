import SwiftUI
import WidgetKit

// MARK: - Home Screen
//
// Both answers are offered, deliberately. A widget that only offers "No" flatters the record
// into a story: someone who spent taps nothing, the day stays open, and the run survives on
// silence. The record is the whole product, so it gets both buttons.
//
// A widget has no confirmation and no undo, so the mistake path is caught in WORDS instead: the
// answered state says where and until when the day can be amended. Nothing else in this file
// may quietly drop that line.
//
// No animation anywhere — widgets do not animate, and the seating beat lives only in the app.
// The moment of the answer is the system's own re-render, which is why there is no hand-rolled
// pending frame here: iOS already dims the widget while the intent runs, and a second treatment
// on top of it would read as a glitch.

struct NoBuyHomeView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: NoBuySnapshot

    var body: some View {
        switch family {
        case .systemMedium: medium
        default: small
        }
    }

    // MARK: Small

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            wordmark

            Spacer(minLength: 4)

            if snapshot.hasNoRecords {
                // "0 days" is not a design: before there is a record, the question IS the state.
                // Sized for the SMALL frame — at subheadline the question takes three lines and
                // pushes "The record starts tonight." into an ellipsis, which turns a promise
                // into a fragment.
                Text("Anything unnecessary today?")
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("The record starts tonight.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else {
                count
                Text(stateLine)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            if snapshot.isAnswered {
                Text(amendLine)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
            } else {
                answerButtons
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(spokenHeadline)
    }

    // MARK: Medium

    private var medium: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                wordmark
                Spacer(minLength: 4)
                if snapshot.hasNoRecords {
                    Text("Anything unnecessary today?")
                        .font(.system(.subheadline, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("The record starts tonight.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    count
                    Text(stateLine)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 6)
                if snapshot.isAnswered {
                    Text(amendLine)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else {
                    answerButtons
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                WeekStrip(days: snapshot.lastSevenDays)
                Text("last 7 days · today \(snapshot.today.spokenName)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)

                // Fixed slot (M-05): the line is present whether or not anything is on hold, so
                // the widget does not change shape between renders.
                Text(snapshot.nearestWait ?? "nothing on hold")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(spokenHeadline + " " + spokenWeek)
    }

    // MARK: Parts

    private var wordmark: some View {
        Text("NOBUY")
            .font(.system(size: 10, weight: .semibold))
            .tracking(1.4)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
    }

    private var count: some View {
        Text("\(snapshot.streak)")
            .font(.system(size: 40, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .accessibilityHidden(true)
    }

    private var answerButtons: some View {
        HStack(spacing: 6) {
            Button(intent: MarkNoBuyIntent()) {
                Text("No")
                    .font(.system(.footnote, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("No — nothing unnecessary today")
            .accessibilityHint(Text(amendSpoken))

            Button(intent: MarkSpentIntent()) {
                Text("Yes")
                    .font(.system(.footnote, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Yes — I bought something")
            .accessibilityHint(Text(amendSpoken))
        }
    }

    private var stateLine: String {
        snapshot.isAnswered
            ? "\(snapshot.dayWord) · today \(snapshot.today.spokenName)"
            : "\(snapshot.dayWord) · today open"
    }

    /// Two lengths, because the small frame is the size the sentence has to survive. Measured on
    /// device: the medium sentence truncates to "amend in NoBuy until…" at systemSmall, and a
    /// truncated amend line is the same as no amend line — the one thing this widget must never
    /// lose, since a mistaken tap here writes a real day and there is no undo inside a widget.
    private var amendLine: String {
        family == .systemSmall
            ? "Amend in NoBuy until midnight."
            : "Answered from here — amend in NoBuy until midnight."
    }

    /// VoiceOver always gets the full sentence, at every size — spoken text does not truncate.
    private var amendSpoken: String {
        "Answered from here — amend in NoBuy until midnight."
    }

    private var spokenHeadline: String {
        guard !snapshot.hasNoRecords else {
            return "NoBuy. Nothing recorded yet. Anything unnecessary today?"
        }
        return snapshot.isAnswered
            ? "NoBuy. \(snapshot.streak) \(snapshot.dayWord) kept. Today answered: \(snapshot.today.spokenName). Amendable in NoBuy until midnight."
            : "NoBuy. \(snapshot.streak) \(snapshot.dayWord) kept. Today not yet answered."
    }

    private var spokenWeek: String {
        let counts = Dictionary(grouping: snapshot.lastSevenDays, by: { $0 }).mapValues(\.count)
        let parts = DayTruth.allCases.compactMap { truth -> String? in
            guard let count = counts[truth], count > 0 else { return nil }
            return "\(count) \(truth.spokenName)"
        }
        return "Last seven days: " + parts.joined(separator: ", ") + "."
    }
}

// MARK: - Lock Screen
//
// Tint mode throws every hue away, so these are drawn hue-blind from the start: the reading is
// the count, the gap in the arc, and the silhouette of each mark. Colour is a courtesy the Home
// Screen adds back, never the channel that carries meaning.
//
// Read-only by decision. An accessory has no confirmation and no undo and lives where accidental
// touches happen — a pocket, a bedside table — and a mistaken tap there would write a false day
// into a record whose whole value is that it is honest. The tap deep-links to the question
// instead.

struct NoBuyAccessoryView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: NoBuySnapshot

    var body: some View {
        switch family {
        case .accessoryRectangular: rectangular
        default: circular
        }
    }

    /// ~76pt. The count wins the centre; the face survives as bezel + index + day arc, with no
    /// numerals and no rim hand — matching the house geometry is not worth costing the read.
    private var circular: some View {
        ZStack {
            Circle().strokeBorder(.tertiary, lineWidth: 1)

            // The arc's terminal GAP is what says "still open" once hue is gone.
            Circle()
                .trim(from: 0, to: snapshot.isAnswered ? 1 : 0.82)
                .stroke(.primary, style: StrokeStyle(lineWidth: 3, lineCap: .butt))
                .rotationEffect(.degrees(-90))
                .padding(3)

            Text("\(snapshot.streak)")
                .font(.system(size: 22, weight: .semibold))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .widgetURL(URL(string: "nobuy://mark"))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            snapshot.isAnswered
                ? "NoBuy. \(snapshot.streak) \(snapshot.dayWord) kept. Today answered."
                : "NoBuy. \(snapshot.streak) \(snapshot.dayWord) kept. Today open."
        )
        .accessibilityHint("Opens NoBuy to answer.")
        .accessibilityAddTraits(.isButton)
    }

    /// Text-first, count first — VoiceOver reads the sentence before the marks, and the marks
    /// are hidden from it entirely.
    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(headline)
                .font(.system(.headline, design: .default))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            WeekStrip(days: snapshot.lastSevenDays)

            // Fixed slot (M-05). Open: the rounded remainder. Answered: the amend sentence,
            // because that is the one thing the answered state owes a surface with no undo.
            // Short form — measured: the Lock Screen rectangular slot truncates anything longer
            // than about twenty characters, and a truncated amend line is no amend line.
            Text(snapshot.remainderOfDay ?? "amend until midnight")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(URL(string: "nobuy://mark"))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken)
    }

    private var headline: String {
        guard !snapshot.hasNoRecords else { return "Anything unnecessary today?" }
        return snapshot.isAnswered
            ? "\(snapshot.streak) \(snapshot.dayWord) · today \(snapshot.today.spokenName)"
            : "\(snapshot.streak) \(snapshot.dayWord) · today open"
    }

    private var spoken: String {
        guard !snapshot.hasNoRecords else { return "NoBuy. Nothing recorded yet." }
        let state = snapshot.isAnswered
            ? "Today answered: \(snapshot.today.spokenName)."
            : "Today open. \(snapshot.remainderOfDay ?? "")"
        return "NoBuy. \(snapshot.streak) \(snapshot.dayWord) kept. \(state)"
    }
}

// MARK: - The week, as marks
//
// The same five truths the calendar draws, at widget scale. Marks are decorative to VoiceOver —
// every state is spoken as a word by the view that owns them.

struct WeekStrip: View {
    let days: [DayTruth]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, truth in
                mark(truth)
            }
        }
        .accessibilityHidden(true)
    }

    /// Drawn here rather than reused from `DayMark`, because a widget must not depend on the
    /// app's themed colour set: in tint mode every fill collapses to one colour and only the
    /// SILHOUETTE survives. Same geometry, `.primary`/`.secondary` instead of the palette.
    @ViewBuilder
    private func mark(_ truth: DayTruth) -> some View {
        switch truth {
        case .kept:
            RoundedRectangle(cornerRadius: 1.5).fill(.primary).frame(width: 3, height: 12)
        case .spent:
            RoundedRectangle(cornerRadius: 1.5).fill(.primary).frame(width: 7, height: 10)
        case .mandatoryOnly:
            // Deliberately drawn as kept: the widget reports the RUN, and an essentials-only day
            // keeps it. The conflation is stated, never hidden — the app draws all five.
            RoundedRectangle(cornerRadius: 1.5).fill(.primary).frame(width: 3, height: 12)
        case .frozen:
            RoundedRectangle(cornerRadius: 3).strokeBorder(.primary, lineWidth: 1.5)
                .frame(width: 6, height: 12)
        case .notYet:
            RoundedRectangle(cornerRadius: 1).fill(.tertiary).frame(width: 3, height: 7)
        }
    }
}

// MARK: - Previews

#Preview("Small — open", as: .systemSmall) {
    NoBuyHomeWidget()
} timeline: {
    NoBuyEntry(date: .now, snapshot: .placeholder)
}

#Preview("Small — first run", as: .systemSmall) {
    NoBuyHomeWidget()
} timeline: {
    NoBuyEntry(date: .now, snapshot: .empty)
}

#Preview("Medium", as: .systemMedium) {
    NoBuyHomeWidget()
} timeline: {
    NoBuyEntry(date: .now, snapshot: .placeholder)
}

#Preview("Circular", as: .accessoryCircular) {
    NoBuyAccessoryWidget()
} timeline: {
    NoBuyEntry(date: .now, snapshot: .placeholder)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    NoBuyAccessoryWidget()
} timeline: {
    NoBuyEntry(date: .now, snapshot: .placeholder)
}
