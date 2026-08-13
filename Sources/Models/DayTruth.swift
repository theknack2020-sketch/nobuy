import Foundation

// MARK: - The five day-truths
//
// A day carries exactly one of five truths, and each is drawn with BOTH geometry and colour
// (M-15) — never colour alone. That is what keeps the calendar readable for a colour-blind
// reader, in Increase Contrast, and on a Lock Screen widget where the system throws every hue
// away and leaves only the silhouette.
//
// The enum lives here, in the model layer, and its PALETTE lives with the views
// (`DayMark.swift`). That split is what lets the widget target compile the meaning without
// dragging in the app's five themes, `UserSettings` and the whole colour resolution chain —
// none of which survives tint mode anyway.

enum DayTruth: String, CaseIterable, Sendable {
    /// Nothing unnecessary was bought.
    case kept
    /// Something discretionary was bought. A fact, never a failure.
    case spent
    /// Only rent, utilities, transport or groceries — the run survives.
    case mandatoryOnly
    /// A freeze was spent to bridge the day.
    case frozen
    /// The day has not been answered. An absence, not a verdict.
    case notYet

    /// What VoiceOver says. Every state is a word; nothing is conveyed by colour alone.
    var spokenName: String {
        switch self {
        case .kept: "kept"
        case .spent: "spent"
        case .mandatoryOnly: "essentials only"
        case .frozen: "frozen"
        case .notYet: "not yet answered"
        }
    }
}
