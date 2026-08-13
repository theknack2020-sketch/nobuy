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
            || persists

        /// Seeds the REAL store instead of an in-memory one.
        ///
        /// Needed for exactly one panel: the widget lives in its own process and reads the shared
        /// store, so it cannot see an in-memory demo. Photographing it against a one-record store
        /// would have shown "1 day" under a caption about glancing at your run. DEBUG-only, opt-in
        /// by launch argument, and it seeds ONCE — a second launch finds records and leaves them.
        static let persists = ProcessInfo.processInfo.arguments.contains("-demoDataPersist")

        /// Photographs the app with Pro unlocked, for the one panel that must show paid value
        /// working rather than locked.
        static let showsProUnlocked = ProcessInfo.processInfo.arguments.contains("-demoPro")
    #else
        static let isActive = false
        static let persists = false
        static let showsProUnlocked = false
    #endif
}
