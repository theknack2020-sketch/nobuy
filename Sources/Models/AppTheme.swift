import SwiftUI

// MARK: - Dial finish
//
// A theme is a FINISH, not a palette (tokens `_meta.category_vs_state`): it swaps the three
// surfaces and nothing else. Ink and accents never move, so a kept day is the same blued steel
// on silver as it is on moss — meaning survives every finish the user picks.
//
// This replaces the v1 themes (mint / ocean / sunset / midnight / forest), which each carried
// their own primary, secondary and accent. That system had a defect the redesign removes: the
// accent moved with the theme, so the colour that meant "kept" was a different colour depending
// on a decoration setting. `migrated(from:)` below maps every old value forward.

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case silver
    case cream
    case salmon
    case slate
    case moss

    var id: String { rawValue }

    /// The house default and the only free finish.
    static let `default` = AppTheme.silver

    // MARK: - Display

    var displayName: String {
        switch self {
        case .silver: "Silver"
        case .cream: "Cream"
        case .salmon: "Salmon"
        case .slate: "Slate"
        case .moss: "Moss"
        }
    }

    /// One finish is free; the other four are part of Pro (`docs/FREE-TIER.md`).
    var isPro: Bool {
        self != .silver
    }

    // MARK: - Surfaces

    func field(_ scheme: ColorScheme) -> Color {
        let dark = scheme == .dark
        switch self {
        case .silver: return dark ? NoBuyTheme.themeFinishesSilverFieldDark : NoBuyTheme.themeFinishesSilverFieldLight
        case .cream: return dark ? NoBuyTheme.themeFinishesCreamFieldDark : NoBuyTheme.themeFinishesCreamFieldLight
        case .salmon: return dark ? NoBuyTheme.themeFinishesSalmonFieldDark : NoBuyTheme.themeFinishesSalmonFieldLight
        case .slate: return dark ? NoBuyTheme.themeFinishesSlateFieldDark : NoBuyTheme.themeFinishesSlateFieldLight
        case .moss: return dark ? NoBuyTheme.themeFinishesMossFieldDark : NoBuyTheme.themeFinishesMossFieldLight
        }
    }

    func dial(_ scheme: ColorScheme) -> Color {
        let dark = scheme == .dark
        switch self {
        case .silver: return dark ? NoBuyTheme.themeFinishesSilverDialDark : NoBuyTheme.themeFinishesSilverDialLight
        case .cream: return dark ? NoBuyTheme.themeFinishesCreamDialDark : NoBuyTheme.themeFinishesCreamDialLight
        case .salmon: return dark ? NoBuyTheme.themeFinishesSalmonDialDark : NoBuyTheme.themeFinishesSalmonDialLight
        case .slate: return dark ? NoBuyTheme.themeFinishesSlateDialDark : NoBuyTheme.themeFinishesSlateDialLight
        case .moss: return dark ? NoBuyTheme.themeFinishesMossDialDark : NoBuyTheme.themeFinishesMossDialLight
        }
    }

    /// The well is only specified for light; in the dark the field already sits below the dial,
    /// so a third darker value would separate nothing and only muddy the two that matter.
    func well(_ scheme: ColorScheme) -> Color {
        guard scheme != .dark else { return field(scheme) }
        switch self {
        case .silver: return NoBuyTheme.themeFinishesSilverWellLight
        case .cream: return NoBuyTheme.themeFinishesCreamWellLight
        case .salmon: return NoBuyTheme.themeFinishesSalmonWellLight
        case .slate: return NoBuyTheme.themeFinishesSlateWellLight
        case .moss: return NoBuyTheme.themeFinishesMossWellLight
        }
    }

    /// The swatch shown in the picker: the finish itself, which is exactly what changes.
    func previewColor(_ scheme: ColorScheme) -> Color { dial(scheme) }

    // MARK: - Migration from the v1 theme names
    //
    // A stored value is the user's choice, and losing it to a rename would silently reset a
    // setting they made on purpose. Mapping is by temperature, not by name: ocean and midnight
    // were the two cool themes, sunset the warm one, forest the green one.

    static func migrated(from raw: String) -> AppTheme? {
        if let direct = AppTheme(rawValue: raw) { return direct }
        switch raw {
        case "mint": return .silver
        case "ocean", "midnight": return .slate
        case "sunset": return .salmon
        case "forest": return .moss
        default: return nil
        }
    }

    // MARK: - Tiers

    static var freeThemes: [AppTheme] { allCases.filter { !$0.isPro } }
    static var proThemes: [AppTheme] { allCases.filter(\.isPro) }
}
