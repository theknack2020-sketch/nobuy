import Foundation

/// Debug-only switch for deterministic demo data during screenshot runs.
/// Active when launched with `-demoData`, or with the UITest convention
/// `-screenshotMode YES` (which lands in the UserDefaults argument domain).
/// Release builds compile this to a constant `false`, so the seeding path is
/// stripped and can never activate in a shipped binary.
enum DemoMode {
    #if DEBUG
        static let isActive = ProcessInfo.processInfo.arguments.contains("-demoData")
            || UserDefaults.standard.bool(forKey: "screenshotMode")
    #else
        static let isActive = false
    #endif
}
