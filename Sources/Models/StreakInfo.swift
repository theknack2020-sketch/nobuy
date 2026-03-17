import Foundation

struct StreakInfo: Equatable, Sendable {
    let currentStreak: Int
    let longestStreak: Int
    let noBuyDaysThisMonth: Int
    let totalDaysThisMonth: Int
    let noBuyPercentageThisMonth: Double

    var monthSummary: String {
        let calendar = Calendar.current
        let monthName = calendar.monthSymbols[calendar.component(.month, from: .now) - 1]
        return "\(monthName): \(totalDaysThisMonth) günün \(noBuyDaysThisMonth)'inde harcama yapmadın"
    }

    static let empty = StreakInfo(
        currentStreak: 0,
        longestStreak: 0,
        noBuyDaysThisMonth: 0,
        totalDaysThisMonth: 0,
        noBuyPercentageThisMonth: 0
    )
}
