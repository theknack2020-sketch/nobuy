import SwiftUI

// MARK: - The five day-truths
//
// A day carries exactly one of five truths, and each is drawn with BOTH geometry and colour
// (M-15) — never colour alone. That is what keeps the calendar readable for a colour-blind
// reader, in Increase Contrast, and on a Lock Screen widget where the system throws every hue
// away and leaves only the silhouette.
//
// Formulas are transcribed from `docs/VISUAL-LANGUAGE.md` § Component vocabulary. They are
// absolute point sizes on purpose: these are instrument parts, not text, so they do not scale
// with Dynamic Type — the CELL grows around them instead.

// MARK: - How a truth is coloured
//
// Kept OUT of `DayTruth` itself: the enum is shared with the widget target, and the widget must
// not compile the app's themed colour set — on the Lock Screen every hue collapses to one and
// only the silhouette survives. So the meaning lives in the model and the palette lives here.

extension DayTruth {
    var color: Color {
        switch self {
        case .kept: .accentKept
        case .spent: .accentSpentMark
        case .mandatoryOnly, .frozen: .stateWait
        case .notYet: .stateNotYet
        }
    }
}

// MARK: - The mark

/// One day, drawn as its mark. Five geometries, one per truth.
///
/// Sizes are the drawn footprint; the caller centres it. A mark never overlaps text and never
/// stacks with another mark (grammar § combination rules).
struct DayMark: View {
    let truth: DayTruth
    /// Increase Contrast substitutes outlines for the quiet fills (accessibility substitution
    /// map). Passed in rather than read here so a widget — which has no such environment — can
    /// state its own answer.
    var increaseContrast = false

    var body: some View {
        switch truth {
        case .kept:
            // 3.5 × 14, r2 — a standing tick in the one kept-accent.
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.accentKept)
                .frame(width: 3.5, height: 14)

        case .spent:
            // 9 × 12, r1.5 — a block, not a tick: the geometry alone separates it from kept
            // even before colour arrives. Increase Contrast adds a 1pt ink outline.
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.accentSpentMark)
                .frame(width: 9, height: 12)
                .overlay {
                    if increaseContrast {
                        RoundedRectangle(cornerRadius: 1.5)
                            .strokeBorder(Color.inkPrimary, lineWidth: 1)
                    }
                }

        case .mandatoryOnly:
            // A shorter tick with a dot beneath: the run survived, but something was paid.
            VStack(spacing: 1) {
                RoundedRectangle(cornerRadius: 1.75)
                    .fill(markColor)
                    .frame(width: 3.5, height: 10)
                RoundedRectangle(cornerRadius: 1)
                    .fill(markColor)
                    .frame(width: 4, height: 4)
            }

        case .frozen:
            // 8 × 14 hollow with a 2pt wall — the day is held, not filled.
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(markColor, lineWidth: 2)
                .frame(width: 8, height: 14)

        case .notYet:
            // 3 × 9 in the hairline value — present, quiet, and clearly not an answer.
            RoundedRectangle(cornerRadius: 1.5)
                .fill(increaseContrast ? Color.inkSecondary : Color.stateNotYet)
                .frame(width: 3, height: 9)
        }
    }

    /// Increase Contrast turns the neutral wait-channel into ink outlines.
    private var markColor: Color {
        increaseContrast ? .inkPrimary : .stateWait
    }
}

// MARK: - Index triangle
//
// Primitive 7. Marks "now" on a dial and "today" on a cell. Always the topmost thing on its
// dial (grammar § draw order).

struct IndexTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Day cell
//
// The calendar's unit: a 46pt-high frame with the numeral top-centre and the mark below it.
// Today notches an index triangle over the top edge and thickens the border to 1.5pt — the
// only cell that is ever outlined in ink.
//
// The cell GROWS with Dynamic Type (to 56pt at XXXL) while the numeral floors at 12 and the
// mark never changes size: an instrument part that shrank would stop being comparable.

struct DayCell: View {
    let day: Int
    let truth: DayTruth
    var isToday = false
    /// Days before the first record: a bare numeral, deliberately not an object.
    var isPreRecord = false
    var logDots: Int = 0
    var hasNote = false

    @ScaledMetric(relativeTo: .caption) private var cellHeight: CGFloat = 46
    @ScaledMetric(relativeTo: .caption) private var numeralSize: CGFloat = 12

    /// The cell grows to 56pt at XXXL and stops there — past that the month stops fitting the
    /// screen, which costs more than the extra points buy.
    private var resolvedHeight: CGFloat { min(max(cellHeight, 46), 56) }
    /// The numeral scales with the user's setting but never drops below its 12pt floor, where
    /// tabular digits stop being unambiguous at cell size.
    private var resolvedNumeral: CGFloat { max(numeralSize, 12) }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(day)")
                .font(.system(size: resolvedNumeral, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(isPreRecord ? Color.stateNotYet : Color.inkSecondary)

            if isPreRecord {
                Spacer(minLength: 0)
            } else {
                DayMark(truth: truth)
                    .frame(height: 14)
            }

            // Mandatory logs accumulate as dots; they never stack on the mark.
            if logDots > 0 {
                HStack(spacing: 2) {
                    ForEach(0 ..< min(logDots, 3), id: \.self) { _ in
                        Circle().fill(Color.stateWait).frame(width: 2.5, height: 2.5)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: resolvedHeight)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.cell)
                .fill(Color.surfaceDial)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.cell)
                        .strokeBorder(
                            isToday ? Color.inkPrimary : Color.inkHairline,
                            lineWidth: isToday ? 1.5 : DS.Stroke.hairline
                        )
                )
        )
        .overlay(alignment: .top) {
            if isToday {
                IndexTriangle()
                    .fill(Color.inkPrimary)
                    .frame(width: 8, height: 5)
                    .offset(y: -2.5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if isPreRecord { return "\(day), before your record starts" }
        var text = "\(day), \(truth.spokenName)"
        if isToday { text = "Today, " + text }
        if hasNote { text += ", has a note" }
        return text
    }
}

#Preview("Marks") {
    HStack(spacing: 20) {
        ForEach(DayTruth.allCases, id: \.self) { DayMark(truth: $0) }
    }
    .padding(40)
    .background(Color.surfaceDial)
}

#Preview("Cells") {
    HStack(spacing: DS.Spacing.cellGap) {
        DayCell(day: 11, truth: .kept)
        DayCell(day: 12, truth: .spent, hasNote: true)
        DayCell(day: 13, truth: .mandatoryOnly, logDots: 2)
        DayCell(day: 14, truth: .frozen)
        DayCell(day: 15, truth: .notYet, isToday: true)
    }
    .padding(DS.Spacing.screenGutter)
    .background(Color.surfaceField)
}
