import SwiftUI

// MARK: - Semantic colour surface (Escapement, v2.0.0)
//
// Every colour in this file resolves from `NoBuyTheme`, which is GENERATED from
// `.design/rounds/r2/tokens/tokens.json` by `~/.agents/ops/gen-theme.mjs`. There is no hex
// literal here and there must never be one in a view: `design-preflight` re-runs the generator
// and fails the submit gate when the generated files drift from the tokens.
//
// The accent contract (tokens `_meta.accent_contract`) is the rule these names encode:
//
//   accentKept   — the answered, kept truth AND the one primary action. Blued steel by day,
//                  lume by night: one job, two worlds. Nothing else may be this colour.
//   accentSpent  — the spent fact. Copper, matte, adult. Never an alarm, never an error, and
//                  never destructive-delete.
//   stateWait    — mandatory, frozen, and any wait in progress: the neither-good-nor-bad
//                  channel. This is why "freeze blue" and "amber" no longer exist — they were
//                  two colours doing one job, and one of them read as a warning.
//   (no fourth)  — destruction is a system alert's job (SwiftUI `.destructive` role). In our own
//                  surfaces it is ink text + a trash glyph + confirmation, never a colour.
//
// Legibility law: ink and accents sit only on field, dial or well. Nothing textual sits on an
// accent except `inkOnAccent`, and no accent ever sits on another accent.

extension Color {
    // MARK: Surfaces — three values, one step apart

    /// The room. Behind everything.
    static let surfaceField = NoBuyTheme.surfaceField
    /// One step above the field: the dial face and any raised card.
    static let surfaceDial = NoBuyTheme.surfaceDial
    /// One step below the field: wells, recessed rows, inset lists.
    static let surfaceWell = NoBuyTheme.surfaceWell
    /// Dims the room behind a door (the paywall sheet). A value, never a blur.
    static let surfaceScrim = NoBuyTheme.surfaceScrim

    // MARK: Ink

    static let inkPrimary = NoBuyTheme.inkPrimary
    static let inkSecondary = NoBuyTheme.inkSecondary
    /// The only thing that may sit on an accent.
    static let inkOnAccent = NoBuyTheme.inkOnAccent
    /// Separators. Measured to a 1.2:1 visibility floor — a rule, not text.
    static let inkHairline = NoBuyTheme.inkHairline
    /// Minor dial ticks and the quietest labels.
    static let inkDialMinor = NoBuyTheme.inkDialMinor

    // MARK: Accents — exactly two, plus one neutral state channel

    /// A kept day and the one primary action.
    static let accentKept = NoBuyTheme.accentKept
    /// The spent fact as a MARK (graphic, measured at a 3:1 floor).
    static let accentSpentMark = NoBuyTheme.accentSpentMark
    /// The spent fact as TEXT (measured at the 4.5:1 text floor). When in doubt, use this one.
    static let accentSpentText = NoBuyTheme.accentSpentText
    /// Mandatory-only days, frozen days, and any wait in progress.
    static let stateWait = NoBuyTheme.stateWait
    /// A day that has not been answered yet. Not a failure — an absence.
    static let stateNotYet = NoBuyTheme.stateNotYet

    // MARK: Washes
    //
    // Derived, never authored: a wash is its accent at a fixed alpha over a surface. They carry
    // no text (the legibility law forbids it), so they need no contrast pair of their own.

    static let accentKeptWash = NoBuyTheme.accentKept.opacity(0.12)
    static let accentSpentWash = NoBuyTheme.accentSpentMark.opacity(0.12)
    static let stateWaitWash = NoBuyTheme.stateWait.opacity(0.12)

    // MARK: - Theme finish (surface swap only)
    //
    // A theme changes the FINISH of the dial — nothing else. Ink and accents never move, which
    // is what keeps meaning stable across all five: a kept day is the same colour on silver as
    // it is on moss. Reading these needs the environment's colour scheme, so they are functions
    // rather than the `@MainActor` static vars the old theme system used.

    @MainActor
    static func themedField(_ scheme: ColorScheme) -> Color {
        UserSettings.shared.currentTheme.field(scheme)
    }

    @MainActor
    static func themedDial(_ scheme: ColorScheme) -> Color {
        UserSettings.shared.currentTheme.dial(scheme)
    }

    @MainActor
    static func themedWell(_ scheme: ColorScheme) -> Color {
        UserSettings.shared.currentTheme.well(scheme)
    }
}

// MARK: - ShapeStyle conveniences
//
// So a view can write `.foregroundStyle(.accentKept)` without spelling out `Color`.

extension ShapeStyle where Self == Color {
    static var accentKept: Color { .accentKept }
    static var accentSpentMark: Color { .accentSpentMark }
    static var accentSpentText: Color { .accentSpentText }
    static var stateWait: Color { .stateWait }
    static var stateNotYet: Color { .stateNotYet }
    static var inkPrimary: Color { .inkPrimary }
    static var inkSecondary: Color { .inkSecondary }
    static var inkOnAccent: Color { .inkOnAccent }
    static var inkHairline: Color { .inkHairline }
    static var inkDialMinor: Color { .inkDialMinor }
    static var surfaceField: Color { .surfaceField }
    static var surfaceDial: Color { .surfaceDial }
    static var surfaceWell: Color { .surfaceWell }
}
