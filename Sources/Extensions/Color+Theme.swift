import SwiftUI

extension Color {
    /// Muted green for no-buy days — dark mode aware.
    /// Deep enough that WHITE text on this fill clears WCAG AA (≥4.5:1) in
    /// both appearances (calendar day numbers, primary CTA done-state).
    static let noBuyGreen = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.22, green: 0.52, blue: 0.36, alpha: 1)
            : UIColor(red: 0.21, green: 0.52, blue: 0.35, alpha: 1)
    })
    /// Lighter green for backgrounds
    static let noBuyGreenLight = Color.noBuyGreen.opacity(0.15)

    /// Muted red for spend days — dark mode aware.
    /// White text on this fill: 4.59:1 light / 4.61:1 dark (WCAG AA for body).
    static let spendRed = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.74, green: 0.26, blue: 0.26, alpha: 1)
            : UIColor(red: 0.78, green: 0.30, blue: 0.30, alpha: 1)
    })
    /// Lighter red for backgrounds
    static let spendRedLight = Color.spendRed.opacity(0.15)

    /// Mandatory spending — dark mode aware amber.
    /// White text on this fill clears 4.5:1 in both appearances.
    static let mandatoryAmber = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.60, green: 0.43, blue: 0.10, alpha: 1)
            : UIColor(red: 0.58, green: 0.42, blue: 0.08, alpha: 1)
    })
    static let mandatoryAmberLight = Color.mandatoryAmber.opacity(0.15)

    /// Streak-freeze blue — opaque and appearance-aware so white text on it
    /// clears WCAG AA (never an alpha wash over an unknown backdrop).
    static let freezeBlue = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.16, green: 0.36, blue: 0.70, alpha: 1)
            : UIColor(red: 0.14, green: 0.34, blue: 0.68, alpha: 1)
    })

    /// Neutral answer-button fill (checklist): dark slate that carries white
    /// text at ~6:1 without borrowing the calendar's red/green semantics.
    static let answerNeutral = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.38, green: 0.41, blue: 0.46, alpha: 1)
            : UIColor(red: 0.35, green: 0.38, blue: 0.42, alpha: 1)
    })

    /// Background tones
    static let surfacePrimary = Color(uiColor: .systemBackground)
    static let surfaceSecondary = Color(uiColor: .secondarySystemBackground)
    static let surfaceTertiary = Color(uiColor: .tertiarySystemBackground)

    /// Text
    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let textTertiary = Color(uiColor: .tertiaryLabel)

    // MARK: - Theme-Aware Colors

    /// Primary theme color — reads from UserSettings
    @MainActor
    static var themePrimary: Color {
        UserSettings.shared.currentTheme.primary
    }

    /// Secondary theme color — reads from UserSettings
    @MainActor
    static var themeSecondary: Color {
        UserSettings.shared.currentTheme.secondary
    }

    /// Accent theme color — reads from UserSettings
    @MainActor
    static var themeAccent: Color {
        UserSettings.shared.currentTheme.accent
    }

    /// Light background tint — reads from UserSettings
    @MainActor
    static var themeBackground: Color {
        UserSettings.shared.currentTheme.primary.opacity(0.08)
    }

    /// Card background tint — reads from UserSettings
    @MainActor
    static var themeCardBackground: Color {
        UserSettings.shared.currentTheme.primary.opacity(0.05)
    }
}

extension ShapeStyle where Self == Color {
    static var noBuyGreen: Color {
        .noBuyGreen
    }

    static var spendRed: Color {
        .spendRed
    }

    static var textPrimary: Color {
        .textPrimary
    }

    static var textSecondary: Color {
        .textSecondary
    }

    static var textTertiary: Color {
        .textTertiary
    }

    static var mandatoryAmber: Color {
        .mandatoryAmber
    }
}
