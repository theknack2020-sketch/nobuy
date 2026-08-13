import SwiftUI

// MARK: - User Settings

@Observable
@MainActor
final class UserSettings {
    static let shared = UserSettings()

    /// Theme stored as raw string in UserDefaults
    var selectedThemeRaw: String {
        get {
            access(keyPath: \.selectedThemeRaw)
            return UserDefaults.standard.string(forKey: "selectedTheme") ?? AppTheme.default.rawValue
        }
        set {
            withMutation(keyPath: \.selectedThemeRaw) {
                UserDefaults.standard.set(newValue, forKey: "selectedTheme")
            }
        }
    }

    /// Current theme enum value.
    ///
    /// Reads through `AppTheme.migrated(from:)` so a v1 install that stored "mint" or "forest"
    /// lands on the equivalent finish instead of silently snapping back to the default — a
    /// stored value is a choice the user made, and a rename is not a reason to discard it.
    var currentTheme: AppTheme {
        get { AppTheme.migrated(from: selectedThemeRaw) ?? .default }
        set { selectedThemeRaw = newValue.rawValue }
    }

    private init() {}
}
