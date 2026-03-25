import SwiftUI

// MARK: - User Settings

@Observable
@MainActor
final class UserSettings {
    static let shared = UserSettings()

    // Theme stored as raw string in UserDefaults
    var selectedThemeRaw: String {
        get {
            access(keyPath: \.selectedThemeRaw)
            return UserDefaults.standard.string(forKey: "selectedTheme") ?? AppTheme.mint.rawValue
        }
        set {
            withMutation(keyPath: \.selectedThemeRaw) {
                UserDefaults.standard.set(newValue, forKey: "selectedTheme")
            }
        }
    }

    /// Current theme enum value
    var currentTheme: AppTheme {
        get { AppTheme(rawValue: selectedThemeRaw) ?? .mint }
        set { selectedThemeRaw = newValue.rawValue }
    }

    private init() {}
}
