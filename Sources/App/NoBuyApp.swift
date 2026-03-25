import SwiftUI
import SwiftData
import CoreSpotlight

// MARK: - Quick Action Types

enum QuickAction: String {
    case markNoBuyDay = "com.ufukozdemir.nobuy.marknobuyday"
    case viewStreak = "com.ufukozdemir.nobuy.viewstreak"
}

// MARK: - Quick Action Handler

@Observable
final class QuickActionHandler {
    var selectedTab: Int?
    var pendingMarkNoBuy = false

    func handle(_ shortcutItem: UIApplicationShortcutItem) {
        guard let action = QuickAction(rawValue: shortcutItem.type) else { return }
        switch action {
        case .markNoBuyDay:
            pendingMarkNoBuy = true
            selectedTab = 0 // Home tab
        case .viewStreak:
            selectedTab = 2 // Stats tab
        }
    }
}

// MARK: - AppDelegate for Quick Action handling

final class AppDelegate: NSObject, UIApplicationDelegate {
    /// Shared handler — injected from NoBuyApp
    var quickActionHandler: QuickActionHandler?

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        quickActionHandler?.handle(shortcutItem)
        completionHandler(true)
    }
}

@main
struct NoBuyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var store = StoreService.shared
    @State private var achievementManager = AchievementManager.shared
    @State private var quickActionHandler = QuickActionHandler()
    @State private var userSettings = UserSettings.shared
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            DayRecord.self,
            MandatoryCategory.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: NoBuyMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView(quickActionHandler: quickActionHandler)
                } else {
                    OnboardingScreen()
                }
            }
            .environment(store)
            .environment(achievementManager)
            .environment(quickActionHandler)
            .environment(userSettings)
            .task {
                appDelegate.quickActionHandler = quickActionHandler
                await store.loadProducts()
                await store.checkEntitlements()
            }
            .task {
                await store.listenForTransactions()
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .onContinueUserActivity(CSSearchableItemActionType) { activity in
                handleSpotlightActivity(activity)
            }
        }
        .modelContainer(modelContainer)
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "nobuy" else { return }
        switch url.host {
        case "mark":
            quickActionHandler.pendingMarkNoBuy = true
            quickActionHandler.selectedTab = 0
        case "streak":
            quickActionHandler.selectedTab = 2
        default:
            break
        }
    }

    private func handleSpotlightActivity(_ activity: NSUserActivity) {
        guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String else { return }
        if identifier.contains("streak") {
            quickActionHandler.selectedTab = 0 // Home tab shows streak
        } else if identifier.contains("achievement") {
            quickActionHandler.selectedTab = 2 // Stats tab shows achievements
        }
    }
}
