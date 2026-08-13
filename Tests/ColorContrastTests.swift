import SwiftUI
import Testing
import UIKit
@testable import NoBuy

/// Contrast, measured against the SHIPPED asset catalog.
///
/// `contrast_check.py` measures `tokens.json`; this measures what the bundle actually resolves,
/// which is the half a JSON file cannot prove — a colorset that never got bundled, a name the
/// generator changed, or an appearance that silently fell back to its light value would all
/// pass the JSON check and fail here.
///
/// **This suite replaces a v1 test that asserted WHITE text over every fill.** That assumption
/// died with the redesign: the legibility law (tokens `_meta.legibility_law`) says nothing
/// textual ever sits on an accent except `inkOnAccent` — and `inkOnAccent` is near-white in
/// light mode and near-BLACK in dark mode. Demanding white-on-accent in both appearances was
/// therefore asking the palette to be something it deliberately is not; the old test failed the
/// new tokens for obeying their own contract. The pairs below are the ones the tokens actually
/// declare in `_meta.contrastPairs`, at the thresholds they declare.
@Suite("Token contrast, resolved from the bundle (WCAG)")
struct ColorContrastTests {
    // MARK: - Measurement

    private func luminance(_ color: UIColor, dark: Bool) -> Double {
        let traits = UITraitCollection(userInterfaceStyle: dark ? .dark : .light)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.resolvedColor(with: traits).getRed(&r, green: &g, blue: &b, alpha: &a)
        func lin(_ c: CGFloat) -> Double {
            let c = Double(c)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
    }

    private func ratio(_ fg: Color, on bg: Color, dark: Bool) -> Double {
        let a = luminance(UIColor(fg), dark: dark)
        let b = luminance(UIColor(bg), dark: dark)
        let (hi, lo) = a > b ? (a, b) : (b, a)
        return (hi + 0.05) / (lo + 0.05)
    }

    /// Every pair the tokens declare, with the threshold they declare it at.
    /// text 4.5 · graphic 3.0 · hairline 1.2 (a rule must be visible, not readable).
    private struct Pair {
        let name: String
        let fg: Color
        let bg: Color
        let min: Double
    }

    private let pairs: [Pair] = [
        .init(name: "ink.primary on field", fg: .inkPrimary, bg: .surfaceField, min: 4.5),
        .init(name: "ink.secondary on field", fg: .inkSecondary, bg: .surfaceField, min: 4.5),
        .init(name: "ink.primary on well", fg: .inkPrimary, bg: .surfaceWell, min: 4.5),
        .init(name: "ink.secondary on well", fg: .inkSecondary, bg: .surfaceWell, min: 4.5),
        .init(name: "accent.kept on field", fg: .accentKept, bg: .surfaceField, min: 4.5),
        .init(name: "accent.kept on dial", fg: .accentKept, bg: .surfaceDial, min: 4.5),
        .init(name: "accent.kept on well", fg: .accentKept, bg: .surfaceWell, min: 3),
        .init(name: "accent.spentText on field", fg: .accentSpentText, bg: .surfaceField, min: 4.5),
        .init(name: "accent.spentMark on dial", fg: .accentSpentMark, bg: .surfaceDial, min: 3),
        .init(name: "state.wait on dial", fg: .stateWait, bg: .surfaceDial, min: 3),
        // The ONE pair that may sit on an accent — and the reason the old white-on-fill test
        // was measuring the wrong thing.
        .init(name: "ink.onAccent on accent.kept", fg: .inkOnAccent, bg: .accentKept, min: 4.5),
        .init(name: "ink.hairline on dial", fg: .inkHairline, bg: .surfaceDial, min: 1.2),
        .init(name: "ink.hairline on field", fg: .inkHairline, bg: .surfaceField, min: 1.2),

        // The instrument value. Declared at the hairline floor, not 4.5 and not 3.0: the round's
        // own failure mode says minors are the FIRST thing a small dial drops, so the reading
        // never depends on them. Its absence from this list is what let 52 sentences drift onto
        // a 2.2:1 colour while the suite stayed green — an unmeasured token is an unenforced one.
        .init(name: "ink.dialMinor on field", fg: .inkDialMinor, bg: .surfaceField, min: 1.2),
        .init(name: "ink.dialMinor on dial", fg: .inkDialMinor, bg: .surfaceDial, min: 1.2),
        .init(name: "ink.dialMinor on well", fg: .inkDialMinor, bg: .surfaceWell, min: 1.2),
    ]

    // MARK: - Tests

    @Test("Every declared token pair clears its threshold in light mode")
    func lightModePairs() {
        for pair in pairs {
            let r = ratio(pair.fg, on: pair.bg, dark: false)
            #expect(r >= pair.min, "\(pair.name) light: \(r) < \(pair.min)")
        }
    }

    @Test("Every declared token pair clears its threshold in dark mode")
    func darkModePairs() {
        for pair in pairs {
            let r = ratio(pair.fg, on: pair.bg, dark: true)
            #expect(r >= pair.min, "\(pair.name) dark: \(r) < \(pair.min)")
        }
    }

    /// Dark is a composition, not an inversion (the direction's own claim). If a colorset had
    /// no dark variant it would resolve identically in both appearances — which is exactly how
    /// a missing "Any/Dark" pair hides.
    @Test("Surfaces and ink actually change between appearances")
    func darkIsNotAnInversionOfNothing() {
        let mustDiffer: [(String, Color)] = [
            ("surface.field", .surfaceField),
            ("surface.dial", .surfaceDial),
            ("ink.primary", .inkPrimary),
            ("accent.kept", .accentKept),
        ]
        for (name, color) in mustDiffer {
            let light = luminance(UIColor(color), dark: false)
            let dark = luminance(UIColor(color), dark: true)
            #expect(abs(light - dark) > 0.01, "\(name) resolves the same in both appearances")
        }
    }

    /// The five finishes swap surfaces only. If a finish ever moved an accent, meaning would
    /// change with a decoration setting — the exact defect the v1 theme system shipped.
    @Test("Every finish keeps the same accents")
    @MainActor
    func finishesDoNotMoveAccents() {
        let keptLight = luminance(UIColor(Color.accentKept), dark: false)
        for theme in AppTheme.allCases {
            UserSettings.shared.currentTheme = theme
            let now = luminance(UIColor(Color.accentKept), dark: false)
            #expect(abs(now - keptLight) < 0.0001, "\(theme.displayName) moved accent.kept")
        }
        UserSettings.shared.currentTheme = .default
    }
}
