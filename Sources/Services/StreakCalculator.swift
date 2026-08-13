import Foundation

enum StreakCalculator {
    /// Calculate all streak information from an array of DayRecords
    static func calculate(from records: [DayRecord]) -> StreakInfo {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // Build a lookup set of no-buy days (includes frozen days)
        let noBuyDates: Set<Date> = Set(
            records
                .filter(\.isNoBuyDay)
                .map { calendar.startOfDay(for: $0.date) }
        )

        // Build a lookup set of frozen dates
        let frozenDates: Set<Date> = Set(
            records
                .filter(\.isFrozen)
                .map { calendar.startOfDay(for: $0.date) }
        )

        // Current streak: count backwards from today. An UNLOGGED today is
        // pending, not broken — start from yesterday so an active streak never
        // reads 0 just because the person hasn't logged yet (a spend record
        // today still legitimately breaks it).
        let recordedDates: Set<Date> = Set(records.map { calendar.startOfDay(for: $0.date) })
        let streakAnchor: Date = if recordedDates.contains(today) {
            today
        } else {
            calendar.date(byAdding: .day, value: -1, to: today) ?? today
        }
        let currentStreak = countStreak(from: streakAnchor, noBuyDates: noBuyDates, frozenDates: frozenDates, calendar: calendar)

        // Longest streak: scan all time
        let longestStreak = findLongestStreak(noBuyDates: noBuyDates, frozenDates: frozenDates, calendar: calendar)

        // This month stats
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let daysSoFar = calendar.dateComponents([.day], from: monthStart, to: today).day! + 1

        let noBuyThisMonth = (0 ..< daysSoFar).count { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: monthStart) else { return false }
            return noBuyDates.contains(date)
        }

        let frozenThisMonth = (0 ..< daysSoFar).count { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: monthStart) else { return false }
            return frozenDates.contains(date)
        }

        let percentage = daysSoFar > 0 ? Double(noBuyThisMonth) / Double(daysSoFar) * 100 : 0

        return StreakInfo(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            noBuyDaysThisMonth: noBuyThisMonth,
            totalDaysThisMonth: daysSoFar,
            noBuyPercentageThisMonth: percentage,
            frozenDaysThisMonth: frozenThisMonth
        )
    }

    /// Count streak backwards from startDate. Frozen days count as streak days (don't break the chain).
    private static func countStreak(
        from startDate: Date,
        noBuyDates: Set<Date>,
        frozenDates: Set<Date>,
        calendar: Calendar
    ) -> Int {
        var streak = 0
        var currentDate = startDate

        while noBuyDates.contains(currentDate) || frozenDates.contains(currentDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDay
        }

        return streak
    }

    /// Find longest streak across all recorded days. Frozen days bridge streaks (don't break them).
    private static func findLongestStreak(
        noBuyDates: Set<Date>,
        frozenDates: Set<Date>,
        calendar: Calendar
    ) -> Int {
        let allContinuousDates = noBuyDates.union(frozenDates)
        guard !allContinuousDates.isEmpty else { return 0 }

        let sortedDates = allContinuousDates.sorted()
        var longest = 1
        var current = 1

        for i in 1 ..< sortedDates.count {
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

    // MARK: - Every run, kept
    //
    // The measure grafted from the rejected Doorframe direction (M-09): **the wall keeps every
    // mark ever made.** An ended run is never deleted, truncated or zeroed — it settles and
    // stays on the record beside the current one.
    //
    // This is not sentiment. The largest churn risk this product has is a person who breaks a
    // streak and stops opening the app; an interface that erases the broken run agrees with
    // them. Stats draws these forever, at full dignity.

    /// One unbroken run of kept days.
    struct Run: Identifiable, Equatable, Sendable {
        let start: Date
        let end: Date
        let days: Int
        /// The run that is still going. Exactly one run can be open, and only ever the last.
        let isOpen: Bool

        var id: TimeInterval { start.timeIntervalSince1970 }
    }

    /// Every run in the record, newest first.
    ///
    /// A run is a block of consecutive kept days (no-spend, essentials-only or frozen — the
    /// three truths that hold a streak). A spent day ends a run. A day with no record ends one
    /// too, EXCEPT today: an unanswered today is pending, not broken, which is the same rule
    /// `calculate(from:)` uses to anchor the current streak.
    static func allRuns(from records: [DayRecord], now: Date = .now) -> [Run] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        let keptDates = Set(records.filter(\.isNoBuyDay).map { calendar.startOfDay(for: $0.date) })
        guard !keptDates.isEmpty else { return [] }

        let sorted = keptDates.sorted()
        var runs: [Run] = []
        var runStart = sorted[0]
        var previous = sorted[0]

        for date in sorted.dropFirst() {
            let expected = calendar.date(byAdding: .day, value: 1, to: previous)
            if let expected, calendar.isDate(date, inSameDayAs: expected) {
                previous = date
                continue
            }
            runs.append(makeRun(start: runStart, end: previous, today: today, calendar: calendar))
            runStart = date
            previous = date
        }
        runs.append(makeRun(start: runStart, end: previous, today: today, calendar: calendar))

        return runs.sorted { $0.end > $1.end }
    }

    private static func makeRun(start: Date, end: Date, today: Date, calendar: Calendar) -> Run {
        let days = (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
        // Open when it reaches today, or reaches yesterday and today has not been answered —
        // the pending case. Anything older has genuinely ended.
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let isOpen = end >= yesterday
        return Run(start: start, end: end, days: days, isOpen: isOpen)
    }
}
