import SwiftUI

extension Color {
    /// Muted green for no-buy days — dark mode aware
    static let noBuyGreen = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.35, green: 0.75, blue: 0.55, alpha: 1)
            : UIColor(red: 0.27, green: 0.63, blue: 0.45, alpha: 1)
    })
    /// Lighter green for backgrounds
    static let noBuyGreenLight = Color.noBuyGreen.opacity(0.15)

    /// Muted red for spend days — dark mode aware
    static let spendRed = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.88, green: 0.40, blue: 0.40, alpha: 1)
            : UIColor(red: 0.78, green: 0.30, blue: 0.30, alpha: 1)
    })
    /// Lighter red for backgrounds
    static let spendRedLight = Color.spendRed.opacity(0.15)

    /// Mandatory spending — dark mode aware amber
    static let mandatoryAmber = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.75, blue: 0.38, alpha: 1)
            : UIColor(red: 0.82, green: 0.65, blue: 0.28, alpha: 1)
    })
    static let mandatoryAmberLight = Color.mandatoryAmber.opacity(0.15)

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
    static var themePrimary: Color { UserSettings.shared.currentTheme.primary }

    /// Secondary theme color — reads from UserSettings
    @MainActor
    static var themeSecondary: Color { UserSettings.shared.currentTheme.secondary }

    /// Accent theme color — reads from UserSettings
    @MainActor
    static var themeAccent: Color { UserSettings.shared.currentTheme.accent }

    /// Light background tint — reads from UserSettings
    @MainActor
    static var themeBackground: Color { UserSettings.shared.currentTheme.primary.opacity(0.08) }

    /// Card background tint — reads from UserSettings
    @MainActor
    static var themeCardBackground: Color { UserSettings.shared.currentTheme.primary.opacity(0.05) }
}

extension ShapeStyle where Self == Color {
    static var noBuyGreen: Color { .noBuyGreen }
    static var spendRed: Color { .spendRed }
    static var textPrimary: Color { .textPrimary }
    static var textSecondary: Color { .textSecondary }
    static var textTertiary: Color { .textTertiary }
    static var mandatoryAmber: Color { .mandatoryAmber }
}
