import AppIntents

struct NoBuyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: MarkNoBuyIntent(),
            phrases: [
                "Mark today as no-buy in \(.applicationName)",
                "I didn't buy anything today in \(.applicationName)",
                "No spend day in \(.applicationName)",
                "I saved money today in \(.applicationName)"
            ],
            shortTitle: "Mark No-Buy Day",
            systemImageName: "checkmark.circle.fill"
        )
        AppShortcut(
            intent: CheckStreakIntent(),
            phrases: [
                "Check my streak in \(.applicationName)",
                "What's my no-buy streak in \(.applicationName)",
                "How long is my streak in \(.applicationName)"
            ],
            shortTitle: "Check Streak",
            systemImageName: "flame.fill"
        )
    }
}
