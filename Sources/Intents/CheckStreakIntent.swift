import AppIntents
import SwiftData

struct CheckStreakIntent: AppIntent {
    static let title: LocalizedStringResource = "Check My Streak"
    static let description = IntentDescription("Check your current no-buy streak")
    static let openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        let container = try ModelContainer(
            for: DayRecord.self, MandatoryCategory.self,
            migrationPlan: NoBuyMigrationPlan.self,
            configurations: config
        )
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<DayRecord>()
        let records = try context.fetch(descriptor)
        let info = StreakCalculator.calculate(from: records)

        if info.currentStreak > 0 {
            return .result(dialog: "Your current streak is \(info.currentStreak) days! Your longest is \(info.longestStreak) days. 🔥")
        } else {
            return .result(dialog: "No active streak right now. Open NoBuy to start one!")
        }
    }
}
