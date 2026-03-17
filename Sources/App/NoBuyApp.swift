import SwiftUI
import SwiftData

@main
struct NoBuyApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var store = StoreService.shared
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            DayRecord.self,
            MandatoryCategory.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingScreen()
                }
            }
            .environment(store)
            .task {
                await store.loadProducts()
                await store.checkEntitlements()
            }
            .task {
                await store.listenForTransactions()
            }
        }
        .modelContainer(modelContainer)
    }
}
