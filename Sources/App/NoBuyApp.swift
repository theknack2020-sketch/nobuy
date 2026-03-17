import SwiftUI
import SwiftData

@main
struct NoBuyApp: App {
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
            MainTabView()
        }
        .modelContainer(modelContainer)
    }
}
