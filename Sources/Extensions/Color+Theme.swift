import SwiftUI

extension Color {
    /// Muted green for no-buy days — sophisticated, not neon
    static let noBuyGreen = Color(red: 0.27, green: 0.63, blue: 0.45)
    /// Lighter green for backgrounds
    static let noBuyGreenLight = Color(red: 0.27, green: 0.63, blue: 0.45).opacity(0.15)

    /// Muted red for spend days — warm, not alarming
    static let spendRed = Color(red: 0.78, green: 0.30, blue: 0.30)
    /// Lighter red for backgrounds
    static let spendRedLight = Color(red: 0.78, green: 0.30, blue: 0.30).opacity(0.15)

    /// Mandatory spending — neutral amber
    static let mandatoryAmber = Color(red: 0.82, green: 0.65, blue: 0.28)
    static let mandatoryAmberLight = Color(red: 0.82, green: 0.65, blue: 0.28).opacity(0.15)

    /// Background tones
    static let surfacePrimary = Color(uiColor: .systemBackground)
    static let surfaceSecondary = Color(uiColor: .secondarySystemBackground)
    static let surfaceTertiary = Color(uiColor: .tertiarySystemBackground)

    /// Text
    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let textTertiary = Color(uiColor: .tertiaryLabel)
}

extension ShapeStyle where Self == Color {
    static var noBuyGreen: Color { .noBuyGreen }
    static var spendRed: Color { .spendRed }
    static var textPrimary: Color { .textPrimary }
    static var textSecondary: Color { .textSecondary }
    static var textTertiary: Color { .textTertiary }
    static var mandatoryAmber: Color { .mandatoryAmber }
}
