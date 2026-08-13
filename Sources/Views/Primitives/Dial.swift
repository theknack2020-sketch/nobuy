import SwiftUI

// MARK: - The dial family
//
// The direction's signature: THE SWEEP — the arc of elapsed waiting, closing clockwise against
// ticks, with the numeric remainder always printed beside it. The same geometry carries all
// three of the product's waits: ten minutes of urge, twenty-four hours of a held item, and the
// day itself closing at midnight.
//
// Four primitives live here (6, 7, 8, 9 of the closed set): the bezel ring with its ticks and
// numerals, the index triangle at zero, the rim hand with its counterweight, and the sweep arc.
//
// Geometry from `docs/VISUAL-LANGUAGE.md`, expressed as ratios of the dial's own radius so the
// same code draws the 266pt face on Today, the 290pt urge timer, the 118pt Stats dial, the
// 104pt paywall gauge and the 24pt complication minis. Below 160pt the minors drop, then the
// numerals; the bezel, index, hand, arc and count never drop (grammar § failure mode).

/// What a dial is counting. Sets the tick pitch, because a 24-hour face and a 10-minute face
/// are not the same instrument.
enum DialScale {
    /// The day closing at midnight: majors every 30° (24 hours), numerals 0/6/12/18.
    case day
    /// The urge timer: majors every 36° (10 minutes).
    case minutes
    /// A held item or any other plain interval — ticks, no numerals.
    case interval

    var majorPitch: Double {
        switch self {
        case .day: 30
        case .minutes: 36
        case .interval: 45
        }
    }

    var numerals: [Int] {
        switch self {
        case .day: [0, 6, 12, 18]
        // Even minutes only, and never 0/10: the top of a ten-minute face already carries the
        // index and the hand's parked position, so a numeral there is covered on the first
        // frame. Four engraved numerals also make the floating outside labels unnecessary —
        // a face that annotates itself from beyond its own bezel is a diagram, not an instrument.
        case .minutes: [2, 4, 6, 8]
        case .interval: []
        }
    }
}

// MARK: - Bezel

/// Primitive 6. The ring every time object sits inside, with its ticks and printed numerals.
struct BezelDial: View {
    let size: CGFloat
    var scale: DialScale = .day

    /// Below this width the dial sheds detail rather than crowding it.
    private var isCompact: Bool { size < 160 }
    private var showsNumerals: Bool { size >= 200 && !scale.numerals.isEmpty }

    /// The bezel inset is 7pt on the 266pt face; on a 24pt complication mini that would eat
    /// more than half the dial, so it scales and floors at 2.
    private var inset: CGFloat { max(min(size * 0.026, 7), 2) }
    private var radius: CGFloat { size / 2 - inset }
    /// Ticks are 10pt majors / 6pt minors on the big face — as a fraction of the radius, with
    /// the same ceiling, so a mini keeps ticks that fit inside its own rim.
    private var majorTick: CGFloat { min(radius * 0.25, 10) }
    private var minorTick: CGFloat { min(radius * 0.15, 6) }

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.inkHairline, lineWidth: DS.Stroke.bezel)
                .frame(width: size - inset * 2, height: size - inset * 2)

            ForEach(majorAngles, id: \.self) { angle in
                tick(length: majorTick, weight: DS.Stroke.tickMajor, angle: angle, color: .inkDialMinor)
            }

            if !isCompact {
                ForEach(minorAngles, id: \.self) { angle in
                    tick(length: minorTick, weight: DS.Stroke.tickMinor, angle: angle, color: .inkHairline)
                }
            }

            if showsNumerals {
                ForEach(scale.numerals, id: \.self) { numeral in
                    // Printed dial numerals are an INSTRUMENT part, not reading text: they are
                    // engraved at a fixed pitch on a fixed face, so they hold 10pt rather than
                    // scaling with Dynamic Type. What scales is everything a user actually
                    // reads — the count, the remainder, the rows.
                    //
                    // Modifier order matters and is easy to get backwards: SwiftUI applies
                    // inside-out, so the counter-rotation must be INNERMOST (keeping the glyph
                    // upright), then the offset pushes it to the rim, then the outer rotation
                    // carries it around the face. Writing the two rotations adjacently — as the
                    // first draft did — cancels them and stacks every numeral at twelve o'clock.
                    Text("\(numeral)")
                        .font(.system(size: 10, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(.inkDialMinor)
                        .rotationEffect(.degrees(-angle(for: numeral)))
                        .offset(y: -(radius - 26))
                        .rotationEffect(.degrees(angle(for: numeral)))
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var majorAngles: [Double] {
        stride(from: 0.0, to: 360.0, by: scale.majorPitch).map { $0 }
    }

    private var minorAngles: [Double] {
        stride(from: scale.majorPitch / 2, to: 360.0, by: scale.majorPitch).map { $0 }
    }

    private func angle(for numeral: Int) -> Double {
        switch scale {
        case .day: Double(numeral) / 24 * 360
        case .minutes: Double(numeral) / 10 * 360
        case .interval: 0
        }
    }

    /// A tick is drawn at the top and rotated into place — the same 10→20 / 10→16 inset the
    /// grammar specifies, expressed from the rim inward.
    private func tick(length: CGFloat, weight: CGFloat, angle: Double, color: Color) -> some View {
        Capsule()
            .fill(color)
            .frame(width: weight, height: length)
            .offset(y: -(radius - length / 2 - min(inset * 0.6, 4)))
            .rotationEffect(.degrees(angle))
    }
}

// MARK: - Sweep arc

/// Primitive 9. The elapsed fraction of a named wait, closing clockwise from the top.
///
/// `progress` is 0…1. The arc NEVER carries the reading alone — a remainder figure sits beside
/// it in every use (M-15), which is also why the Lock Screen widget survives losing all colour.
struct SweepArc: View {
    let size: CGFloat
    let progress: Double
    var color: Color = .accentKept
    /// An open-ended wait (nothing elapsed yet) draws the rail only.
    var isOpen: Bool = false

    /// On the 266pt face the arc sits 22pt inside the bezel. On a complication mini there is no
    /// room for that inset, so the arc rides the bezel line itself — which is exactly what the
    /// grammar specifies for the 22pt mini (r10, 2.5pt arc). Without the floor the radius goes
    /// NEGATIVE below 58pt and the arc draws as a starburst.
    private var bezelRadius: CGFloat { size / 2 - max(min(size * 0.026, 7), 2) }
    private var radius: CGFloat { max(bezelRadius - 22, bezelRadius * 0.82) }
    private var weight: CGFloat { size < 60 ? 2.5 : DS.Stroke.arc }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.inkHairline, lineWidth: weight)
                .frame(width: radius * 2, height: radius * 2)

            if !isOpen {
                Circle()
                    .trim(from: 0, to: max(0, min(progress, 1)))
                    .stroke(color, style: StrokeStyle(lineWidth: weight, lineCap: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Rim hand

/// Primitive 8. The hand that SEATS into its index when today is answered — the product's only
/// expressive beat. Shaft plus counterweight, so it reads as a mechanism and not as a pointer.
struct RimHand: View {
    let size: CGFloat
    /// 0…1 around the face, measured clockwise from the top.
    let position: Double
    var color: Color = .accentKept

    private var radius: CGFloat { size / 2 - 7 }

    // The grammar gives the hand as "from r−80 to r−108" on the 266pt face: a short shaft
    // riding NEAR THE RIM, between 80pt and 108pt from the centre of a 126pt radius — this is
    // a rim hand, which is what the direction is named for.
    //
    // Two readings were tried and both were wrong on screen, so they are recorded here rather
    // than re-derived by the next person: reading the numbers as insets from the rim puts the
    // shaft on top of the printed numerals at r−26; reading them as a short hand near the
    // centre puts it straight through the count. It rides the rim, and it crosses a numeral
    // occasionally — which is what a hand does on a real face.
    //
    // Ratios of the radius, so the same hand draws on the 104pt paywall gauge and the 24pt
    // complication minis, where an absolute r−80 would go negative.
    private var outerRadius: CGFloat { radius * 0.86 }
    private var innerRadius: CGFloat { radius * 0.63 }
    private var shaftLength: CGFloat { max(outerRadius - innerRadius, 6) }

    var body: some View {
        ZStack {
            Capsule()
                .fill(color)
                .frame(width: DS.Stroke.hand, height: shaftLength)
                .offset(y: -(innerRadius + shaftLength / 2))

            // The counterweight sits just inboard of the shaft — what makes the pair read as a
            // mechanism rather than an arrow.
            Circle()
                .fill(color)
                .frame(width: 3.5, height: 3.5)
                .offset(y: -(innerRadius - 5))
        }
        .rotationEffect(.degrees(position * 360))
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Remainder figure

/// Primitive 10. The number that always accompanies an arc: tabular, and stated in words the
/// widget can round honestly ("about 10 hours left" rather than a clock it cannot keep ticking).
struct RemainderFigure: View {
    let value: String
    var caption: String?

    /// Unlike the engraved dial numerals, a remainder is READ — so it scales with the user's
    /// text size, with a 13pt floor to stay tabular-legible beside the arc.
    @ScaledMetric(relativeTo: .footnote) private var valueSize: CGFloat = 13

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: max(valueSize, 13), weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.inkPrimary)
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.inkSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - The assembled face

/// Bezel + arc + hand + index, composed in the grammar's draw order:
/// field → dial face (bezel, ticks, numerals) → arc → hand/index → centre content.
struct DialFace<Center: View>: View {
    let size: CGFloat
    var scale: DialScale = .day
    var progress: Double
    var handPosition: Double?
    var arcColor: Color = .accentKept
    var isOpen: Bool = false
    @ViewBuilder var center: () -> Center

    /// The face is the ONE surface a finish moves, which is what the promise actually says:
    /// "the finish changes, the truth doesn't". Ink, ticks, arc and index are read from the
    /// fixed palette above and never move — a kept day is the same colour on silver as on moss.
    ///
    /// Wired here rather than by swapping `Color.surfaceDial` app-wide: the finish is a property
    /// of the INSTRUMENT, and repainting every card and sheet with it would break exactly the
    /// stability the sentence promises. Before this, the picker changed nothing but the share
    /// card — a paid row that did nothing.
    @Environment(\.colorScheme) private var colorScheme
    @State private var settings = UserSettings.shared

    /// Same inset rule as the bezel, so the face and its ring stay concentric at every size.
    private var faceInset: CGFloat { max(min(size * 0.026, 7), 2) }

    var body: some View {
        ZStack {
            Circle()
                .fill(settings.currentTheme.dial(colorScheme))
                .frame(width: size - faceInset * 2, height: size - faceInset * 2)

            BezelDial(size: size, scale: scale)
            SweepArc(size: size, progress: progress, color: arcColor, isOpen: isOpen)

            if let handPosition {
                RimHand(size: size, position: handPosition, color: arcColor)
            }

            // The index is always topmost on its dial (grammar § draw order).
            IndexTriangle()
                .fill(Color.inkPrimary)
                .frame(width: min(size * 0.045, 12), height: min(size * 0.038, 10))
                .offset(y: -(size / 2 - max(min(size * 0.026, 7), 2)))

            center()
        }
        .frame(width: size, height: size)
    }
}

#Preview("Day face") {
    DialFace(size: 266, progress: 0.62, handPosition: 0.62) {
        VStack(spacing: 2) {
            Text("23")
                .font(.system(size: 78, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.inkPrimary)
            Text("days kept")
                .font(.caption)
                .foregroundStyle(.inkSecondary)
        }
    }
    .padding(DS.Spacing.screenGutter)
    .background(Color.surfaceField)
}

#Preview("Complication mini") {
    HStack(spacing: DS.Spacing.lg) {
        DialFace(size: 24, scale: .interval, progress: 0.4, handPosition: nil) { EmptyView() }
        DialFace(size: 104, scale: .day, progress: 0.63, handPosition: nil) { EmptyView() }
    }
    .padding(DS.Spacing.screenGutter)
    .background(Color.surfaceField)
}
