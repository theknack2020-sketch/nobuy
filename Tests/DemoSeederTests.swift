import Foundation
import Testing
@testable import NoBuy

@Suite("DemoSeeder")
@MainActor
struct DemoSeederTests {
    @Test("Demo records produce the 23-day hero streak")
    func heroStreak() {
        let records = DemoSeeder.makeRecords()
        let info = StreakCalculator.calculate(from: records)
        #expect(info.currentStreak == 23)
        #expect(info.noBuyDaysThisMonth > 0)
    }

    @Test("Dataset is deterministic and structurally sound")
    func structure() {
        let calendar = Calendar.current
        let records = DemoSeeder.makeRecords()

        // 90 days, one record per day, no duplicates.
        #expect(records.count == 90)
        let normalized = Set(records.map { calendar.startOfDay(for: $0.date) })
        #expect(normalized.count == records.count)

        // The streak boundary at day 23 back is a plain discretionary spend.
        let startOfToday = calendar.startOfDay(for: .now)
        let boundaryDate = calendar.date(byAdding: .day, value: -23, to: startOfToday)!
        let boundary = records.first { calendar.startOfDay(for: $0.date) == boundaryDate }
        #expect(boundary?.didSpend == true)
        #expect(boundary?.isMandatoryOnly == false)
        #expect(boundary?.isFrozen == false)

        // Exactly one frozen day (the calendar shield state).
        #expect(records.count(where: \.isFrozen) == 1)
    }
}
