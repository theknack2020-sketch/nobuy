import Foundation

struct StreakInfo: Equatable, Sendable {
    let currentStreak: Int
    let longestStreak: Int
    let noBuyDaysThisMonth: Int
    let totalDaysThisMonth: Int
    let noBuyPercentageThisMonth: Double
    let frozenDaysThisMonth: Int

    var monthSummary: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM"
        let monthName = formatter.string(from: .now)
        return "\(monthName): \(noBuyDaysThisMonth) of \(totalDaysThisMonth) days no-spend"
    }

    static let empty = StreakInfo(
        currentStreak: 0,
        longestStreak: 0,
        noBuyDaysThisMonth: 0,
        totalDaysThisMonth: 0,
        noBuyPercentageThisMonth: 0,
        frozenDaysThisMonth: 0
    )
}
