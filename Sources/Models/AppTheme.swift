import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case mint
    case ocean
    case sunset
    case midnight
    case forest

    var id: String { rawValue }

    // MARK: - Display Info

    var displayName: String {
        switch self {
        case .mint: return "Mint"
        case .ocean: return "Ocean"
        case .sunset: return "Sunset"
        case .midnight: return "Midnight"
        case .forest: return "Forest"
        }
    }

    var isPro: Bool {
        switch self {
        case .mint, .ocean: return false
        case .sunset, .midnight, .forest: return true
        }
    }

    // MARK: - Theme Colors

    /// Primary brand color — used for main UI accents
    var primary: Color {
        switch self {
        case .mint:
            return Color(red: 0.27, green: 0.63, blue: 0.45)
        case .ocean:
            return Color(red: 0.20, green: 0.47, blue: 0.75)
        case .sunset:
            return Color(red: 0.90, green: 0.42, blue: 0.30)
        case .midnight:
            return Color(red: 0.45, green: 0.38, blue: 0.82)
        case .forest:
            return Color(red: 0.22, green: 0.55, blue: 0.35)
        }
    }

    /// Secondary color — lighter variant for fills and backgrounds
    var secondary: Color {
        switch self {
        case .mint:
            return Color(red: 0.35, green: 0.75, blue: 0.55)
        case .ocean:
            return Color(red: 0.35, green: 0.62, blue: 0.88)
        case .sunset:
            return Color(red: 0.95, green: 0.60, blue: 0.35)
        case .midnight:
            return Color(red: 0.60, green: 0.52, blue: 0.92)
        case .forest:
            return Color(red: 0.40, green: 0.72, blue: 0.48)
        }
    }

    /// Accent color — for highlights, badges, CTAs
    var accent: Color {
        switch self {
        case .mint:
            return Color(red: 0.18, green: 0.80, blue: 0.60)
        case .ocean:
            return Color(red: 0.25, green: 0.78, blue: 0.92)
        case .sunset:
            return Color(red: 1.00, green: 0.72, blue: 0.30)
        case .midnight:
            return Color(red: 0.75, green: 0.55, blue: 1.00)
        case .forest:
            return Color(red: 0.55, green: 0.85, blue: 0.45)
        }
    }

    /// Gradient start color
    var gradientStart: Color {
        primary
    }

    /// Gradient end color
    var gradientEnd: Color {
        secondary
    }

    /// Preview dot color — shown in theme picker
    var previewColor: Color {
        primary
    }

    /// Secondary preview color — for multi-color dots
    var previewSecondaryColor: Color {
        accent
    }

    // MARK: - Free Themes

    static var freeThemes: [AppTheme] {
        allCases.filter { !$0.isPro }
    }

    static var proThemes: [AppTheme] {
        allCases.filter { $0.isPro }
    }
}
