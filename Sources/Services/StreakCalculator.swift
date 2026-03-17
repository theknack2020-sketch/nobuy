import Foundation

enum StreakCalculator {

    /// Calculate all streak information from an array of DayRecords
    static func calculate(from records: [DayRecord]) -> StreakInfo {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // Build a lookup set of no-buy days
        let noBuyDates: Set<Date> = Set(
            records
                .filter { $0.isNoBuyDay }
                .map { calendar.startOfDay(for: $0.date) }
        )

        // Current streak: count backwards from today
        let currentStreak = countStreak(from: today, noBuyDates: noBuyDates, calendar: calendar)

        // Longest streak: scan all time
        let longestStreak = findLongestStreak(noBuyDates: noBuyDates, calendar: calendar)

        // This month stats
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let daysSoFar = calendar.dateComponents([.day], from: monthStart, to: today).day! + 1

        let noBuyThisMonth = (0..<daysSoFar).count { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: monthStart) else { return false }
            return noBuyDates.contains(date)
        }

        let percentage = daysSoFar > 0 ? Double(noBuyThisMonth) / Double(daysSoFar) * 100 : 0

        return StreakInfo(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            noBuyDaysThisMonth: noBuyThisMonth,
            totalDaysThisMonth: daysSoFar,
            noBuyPercentageThisMonth: percentage
        )
    }

    private static func countStreak(
        from startDate: Date,
        noBuyDates: Set<Date>,
        calendar: Calendar
    ) -> Int {
        var streak = 0
        var currentDate = startDate

        while noBuyDates.contains(currentDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDay
        }

        return streak
    }

    private static func findLongestStreak(
        noBuyDates: Set<Date>,
        calendar: Calendar
    ) -> Int {
        guard !noBuyDates.isEmpty else { return 0 }

        let sortedDates = noBuyDates.sorted()
        var longest = 1
        var current = 1

        for i in 1..<sortedDates.count {
            let diff = calendar.dateComponents([.day], from: sortedDates[i - 1], to: sortedDates[i]).day ?? 0
            if diff == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }

        return longest
    }
}
