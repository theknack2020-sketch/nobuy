import CoreSpotlight
import SwiftData
import SwiftUI
import TipKit

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
        _: UIApplication,
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
    @AppStorage("lastSeenVersion") private var lastSeenVersion = ""
    @State private var showWhatsNew = false
    @State private var store = StoreService.shared
    @State private var achievementManager = AchievementManager.shared
    @State private var quickActionHandler = QuickActionHandler()
    @State private var userSettings = UserSettings.shared
    @State private var storeOpenFailed = false
    let modelContainer: ModelContainer

    init() {
        // Bind the schema to its versioned declaration so the migration plan
        // is anchored before the first real V2 change.
        let schema = Schema(versionedSchema: NoBuySchema.self)
        // Demo runs use a throwaway in-memory store so a developer's real
        // records can never be touched by a screenshot session.
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: DemoMode.isActive)
        do {
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: NoBuyMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            // Never crash-loop at launch (2.1(a)): fall back to a throwaway
            // in-memory store and tell the user, leaving the on-disk store
            // untouched for the next launch.
            AppLogger.data.error("Could not open persistent store: \(error.localizedDescription)")
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                modelContainer = try ModelContainer(for: schema, configurations: [fallback])
                _storeOpenFailed = State(initialValue: true)
            } catch {
                fatalError("Could not create even an in-memory ModelContainer: \(error)")
            }
        }

        #if DEBUG
            if DemoMode.isActive {
                DemoSeeder.seed(into: modelContainer)
                Tips.hideAllTipsForTesting()
            }
        #endif

        try? Tips.configure([
            .displayFrequency(.daily)
        ])
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
            .alert("Couldn't open your data", isPresented: $storeOpenFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("NoBuy couldn't open its database this time, so nothing you log right now will be kept. Your saved data is untouched — please quit and reopen the app.")
            }
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
            .onAppear {
                checkWhatsNew()
            }
            .sheet(isPresented: $showWhatsNew) {
                WhatsNewView()
                    .interactiveDismissDisabled(false)
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

    private func checkWhatsNew() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        guard hasCompletedOnboarding,
              !currentVersion.isEmpty,
              lastSeenVersion != currentVersion else { return }
        // Don't show on fresh install (lastSeenVersion is empty and onboarding just completed)
        guard !lastSeenVersion.isEmpty else {
            lastSeenVersion = currentVersion
            return
        }
        lastSeenVersion = currentVersion
        showWhatsNew = true
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
