import CoreSpotlight
import SwiftData
import SwiftUI

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
        // The widget cannot read the app's private container, so v2.0.0 moves the store into the
        // App Group — copy, verify, then switch, with the old file left in place. This runs
        // BEFORE the container is opened, because the container must be pointed at whichever
        // store the move settled on (`NoBuyStore.resolvedStoreURL`).
        if !DemoMode.isActive || DemoMode.persists {
            switch NoBuyStore.migrateToAppGroupIfNeeded() {
            case .notNeeded:
                break
            case let .migrated(records):
                AppLogger.data.info("Records moved to the App Group: \(records) days")
            case let .keptLegacy(reason):
                AppLogger.data.error("Staying on the old store — \(reason)")
            }
        }

        do {
            // Demo runs use a throwaway in-memory store so a developer's real
            // records can never be touched by a screenshot session.
            modelContainer = try NoBuyStore.makeContainer(inMemory: DemoMode.isActive && !DemoMode.persists)
        } catch {
            // Never crash-loop at launch (2.1(a)): fall back to a throwaway
            // in-memory store and tell the user, leaving the on-disk store
            // untouched for the next launch.
            AppLogger.data.error("Could not open persistent store: \(error.localizedDescription)")
            do {
                modelContainer = try NoBuyStore.makeContainer(inMemory: true)
                _storeOpenFailed = State(initialValue: true)
            } catch {
                fatalError("Could not create even an in-memory ModelContainer: \(error)")
            }
        }

        #if DEBUG
            // A panel that depends on a finish sets it here, so the set is reproducible from the
            // launch argument alone rather than from whatever the simulator happened to store.
            if let finish = ScreenshotTour.finish {
                UserDefaults.standard.set(finish, forKey: "selectedTheme")
            }
            if DemoMode.isActive {
                DemoSeeder.seed(into: modelContainer, replacingExisting: DemoMode.persists)
                // Synchronously, at init. `checkEntitlements()` also unlocks demo runs, but it is
                // awaited from a `.task` and the first frames render before it lands — which is
                // precisely the frame a screenshot captures, gate language and all.
                if DemoMode.showsProUnlocked { store.forceProForDemo() }
            }
        #endif

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
                // The review gate counts sessions as well as positive actions; without this
                // call the session half of the policy would never advance and the prompt
                // could never legitimately fire (rule 8: built is not wired).
                RatingPrompt.shared.markSession()
                // Entitlements FIRST. Knowing whether this person is Pro needs no network, while
                // `loadProducts()` does — and behind it the whole app renders its free-tier state
                // for as long as the product fetch takes, which on a slow or offline launch means
                // a paying customer briefly sees locks on things they own.
                await store.checkEntitlements()
                await store.loadProducts()
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
