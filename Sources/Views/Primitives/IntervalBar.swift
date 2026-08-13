import SwiftUI

// MARK: - Interval bar (primitive 11)
//
// A run of days, drawn as a bar. This primitive carries the ONE measure grafted from the
// rejected Doorframe direction (M-09): **the wall keeps every mark ever made.** An ended run is
// never deleted, truncated or zeroed — it settles into the wait-colour and stays on the rail
// beside the current one.
//
// That is not decoration. The largest churn risk this product has is a person who breaks a
// streak and stops opening the app; a design that erases the broken run agrees with them.
//
// Formula (`docs/VISUAL-LANGUAGE.md`): height 10 (7 dense), r5; settled = wait colour;
// open = kept colour with an open end; length = days / best × rail width.

struct IntervalBar: View {
    /// Days in this run.
    let days: Int
    /// The longest run on record — the rail's full width.
    let best: Int
    /// An open run is the one still going: it gets the kept accent and an unfinished end.
    var isOpen: Bool = false
    /// Stats packs many runs into one screen; dense drops the bar to 7pt.
    var isDense: Bool = false

    private var height: CGFloat { isDense ? 7 : 10 }
    private var fraction: Double {
        guard best > 0 else { return 0 }
        return min(Double(days) / Double(best), 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // The rail: the full width of the best run, always drawn. A run is only
                // meaningful against the record it is measured on.
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.surfaceWell)
                    .frame(height: height)

                if isOpen {
                    // An open run has no cap on its leading end — it has not finished, and a
                    // rounded end would say it had.
                    UnevenRoundedRectangle(
                        topLeadingRadius: height / 2,
                        bottomLeadingRadius: height / 2,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                    .fill(Color.accentKept)
                    .frame(width: max(geo.size.width * fraction, height), height: height)
                } else {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.stateWait)
                        .frame(width: max(geo.size.width * fraction, height), height: height)
                }
            }
            .frame(height: height)
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isOpen ? "Current run, \(days) days" : "Ended run, \(days) days")
    }
}

// MARK: - Well slot row (primitive 12)
//
// The complication row: a glyph, a label, and a detail — the shape every wait, log and setting
// takes when it sits in the well. Fixed slots (M-05): the row renders even when its value is
// empty, because an element that appears and disappears reads as disorder.

struct WellSlotRow<Trailing: View>: View {
    let glyph: String
    let label: String
    var detail: String?
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: glyph)
                .font(.footnote)
                .foregroundStyle(.stateWait)
                .frame(width: 22)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.inkPrimary)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.inkSecondary)
                }
            }

            Spacer(minLength: DS.Spacing.sm)

            trailing()
        }
        .frame(minHeight: 44)
        .padding(.horizontal, DS.Spacing.lg)
        .background(Color.surfaceWell)
        .accessibilityElement(children: .combine)
    }
}

extension WellSlotRow where Trailing == EmptyView {
    init(glyph: String, label: String, detail: String? = nil) {
        self.init(glyph: glyph, label: label, detail: detail) { EmptyView() }
    }
}

#Preview("Runs") {
    VStack(alignment: .leading, spacing: DS.Spacing.md) {
        IntervalBar(days: 23, best: 41, isOpen: true)
        IntervalBar(days: 41, best: 41)
        IntervalBar(days: 12, best: 41)
        IntervalBar(days: 3, best: 41, isDense: true)
    }
    .padding(DS.Spacing.screenGutter)
    .background(Color.surfaceField)
}

#Preview("Well rows") {
    VStack(spacing: DS.Stroke.hairline) {
        WellSlotRow(glyph: "hourglass", label: "Wireless earbuds", detail: "about 10 hours left")
        WellSlotRow(glyph: "snowflake", label: "Freeze", detail: "held, August")
        WellSlotRow(glyph: "list.bullet", label: "Essentials", detail: "Rent, Utilities, Transport")
    }
    .background(Color.surfaceField)
}
