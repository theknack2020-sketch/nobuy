import SwiftUI

// MARK: - Design System Constants (Escapement, v2.0.0)
//
// Values transcribed from `.design/rounds/r2/tokens/tokens.json` — the same file that generates
// `NoBuyTheme`. Colour is generated; these are the non-colour tokens (space, radius, stroke,
// motion), which have no catalog equivalent and live here instead.
//
// Three doctrines from the tokens are enforced by what this file DOES NOT offer:
//
//   · **Shadow doctrine: none.** Depth is the bezel line plus one value step (dial above field,
//     well below it). The paywall dims the room behind it with `surfaceScrim` — a value, not a
//     blur. The old `DS.Shadow` presets are kept as no-ops so the ~90 existing call sites keep
//     compiling while the screens are rebuilt; each one is removed as its screen is redrawn.
//   · **No gradient as decoration.** `DS.Gradient` is likewise neutralised: every preset now
//     resolves to a flat surface value. A gradient that survives as "just a subtle tint" is the
//     exact thing that made v1 read as generic.
//   · **Radius is per-JOB, never one number everywhere:** circles for time, capsules for
//     actions, 12 for sheets, 6 for day cells, 0 for ruled lists.

enum DS {
    /// 4pt base. The named steps are the token ladder [4, 8, 12, 16, 20, 26, 34]; the legacy
    /// names are kept so existing layout code keeps its meaning, with `xxl` and `xxxl` moved
    /// onto the token values (24 → 26, 32 → 34).
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 26
        static let xxxl: CGFloat = 34
        static let huge: CGFloat = 44

        /// The screen's horizontal margin. One number, everywhere.
        static let screenGutter: CGFloat = 26
        /// Between day cells in the calendar table.
        static let cellGap: CGFloat = 6
    }

    /// Radius by job (tokens `radius.doctrine`), not by size.
    enum Radius {
        /// Day cells.
        static let cell: CGFloat = 6
        /// Sheets and raised cards.
        static let sheet: CGFloat = 12
        /// Ruled lists and tables carry no radius at all.
        static let table: CGFloat = 0

        // Legacy names, mapped onto the job values above.
        static let sm: CGFloat = cell
        static let md: CGFloat = sheet
        static let lg: CGFloat = sheet
        static let xl: CGFloat = sheet
    }

    /// Line weights. Everything that separates or draws the instrument is one of these.
    enum Stroke {
        static let hairline: CGFloat = 1
        static let tickMinor: CGFloat = 1.5
        static let tickMajor: CGFloat = 2
        static let hand: CGFloat = 3
        static let arc: CGFloat = 4
        static let bezel: CGFloat = 1
    }

    /// Motion. Exactly one expressive beat exists in the product; everything else is functional.
    enum Anim {
        /// State swaps, sheet presents, tab changes: 200ms easeOut.
        static let functional = Animation.easeOut(duration: 0.2)

        /// THE BEAT — the day hand seats into its index with a single overshoot. This is the
        /// only spring in the app, and it fires only when today is answered.
        static let beat = Animation.spring(response: 0.55, dampingFraction: 0.75)

        /// Reduce Motion substitute for the beat: a crossfade, never "nothing happens".
        static let beatReduced = Animation.easeOut(duration: 0.2)

        /// Sheet presentation.
        static let sheet = Animation.easeOut(duration: 0.32)

        /// A gauge drawing itself once (paywall, onboarding).
        static let gauge = Animation.easeOut(duration: 0.24)

        // Legacy names — all resolve to the functional curve. The product no longer has three
        // speeds of spring; it has one beat and one functional curve.
        static let quick = functional
        static let normal = functional
        static let slow = functional
        static let stagger: Double = 0.05
    }

    // MARK: - Neutralised legacy presets
    //
    // Kept so the pre-redesign screens compile while they are rebuilt one at a time. Each is
    // visually inert: a gradient that is one flat value, a shadow with zero radius. When the
    // last screen is redrawn these go, and the slop scan will say so.

    enum Gradient {
        static var header: LinearGradient { flat(.surfaceDial) }
        static var card: LinearGradient { flat(.clear) }
        static var button: LinearGradient { flat(.accentKept) }
        static var glow: RadialGradient {
            RadialGradient(colors: [.clear, .clear], center: .center, startRadius: 0, endRadius: 1)
        }

        private static func flat(_ color: Color) -> LinearGradient {
            LinearGradient(colors: [color, color], startPoint: .top, endPoint: .bottom)
        }
    }

    enum Glass {
        /// Materials are gone: the tokens' shadow doctrine replaces blur with a value step.
        static let ultraThin = Material.ultraThin
        static let regular = Material.regular
        static let thick = Material.thick
    }

    enum Shadow {
        static let card = ShadowStyle.none
        static let button = ShadowStyle.none
        static let floating = ShadowStyle.none
    }
}

// MARK: - Shadow Style Helper

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    /// The only shadow this product ships.
    static let none = ShadowStyle(color: .clear, radius: 0, x: 0, y: 0)
}

extension View {
    /// Applies a DS.Shadow preset. Every preset is inert by design — see the shadow doctrine at
    /// the top of this file.
    func shadow(_ style: ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }

    /// A hairline rule. The product's only separator.
    func hairlineBorder(_ shape: some InsettableShape) -> some View {
        overlay(shape.strokeBorder(Color.inkHairline, lineWidth: DS.Stroke.hairline))
    }
}
