import AppIntents
import SwiftData

struct MarkNoBuyIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Today as No-Buy"
    static let description = IntentDescription("Mark today as a no-spend day in NoBuy")
    static let openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        let container = try ModelContainer(
            for: DayRecord.self, MandatoryCategory.self,
            migrationPlan: NoBuyMigrationPlan.self,
            configurations: config
        )
        let context = ModelContext(container)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        let descriptor = FetchDescriptor<DayRecord>(predicate: #Predicate { record in
            record.date >= today
        })
        let existing = try context.fetch(descriptor)
        let todayRecord = existing.first { calendar.isDate($0.date, inSameDayAs: today) }

        if let record = todayRecord {
            record.didSpend = false
            record.isMandatoryOnly = false
        } else {
            let record = DayRecord(date: today, didSpend: false)
            context.insert(record)
        }
        try context.save()

        return .result(dialog: "Today marked as no-buy! Keep your streak going! 🔥")
    }
}
