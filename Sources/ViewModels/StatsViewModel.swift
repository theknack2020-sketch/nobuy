import Foundation
import Observation
import os

// MARK: - Data Transfer Structures

struct MonthlyData: Identifiable {
    let id = UUID()
    let month: Date
    let label: String
    let noBuyCount: Int
    let totalDays: Int

    var percentage: Double {
        totalDays > 0 ? Double(noBuyCount) / Double(totalDays) * 100 : 0
    }
}

struct WeekdayData: Identifiable {
    let id = UUID()
    let weekday: Int          // 1 = Monday … 7 = Sunday
    let label: String
    let noBuyCount: Int
    let totalRecorded: Int

    var percentage: Double {
        totalRecorded > 0 ? Double(noBuyCount) / Double(totalRecorded) * 100 : 0
    }
}

struct HeatmapDay: Identifiable {
    let id = UUID()
    let date: Date
    let weekOfYear: Int
    let weekday: Int          // 1 = Monday … 7 = Sunday
    let status: HeatmapStatus
}

enum HeatmapStatus {
    case noBuy
    case spent
    case unrecorded
    case future
}

struct TrendComparison {
    let thisMonthPercentage: Double
    let lastMonthPercentage: Double
    let thisMonthNoBuy: Int
    let thisMonthTotal: Int
    let lastMonthNoBuy: Int
    let lastMonthTotal: Int

    var delta: Double { thisMonthPercentage - lastMonthPercentage }
    var isImproving: Bool { delta >= 0 }
}

// MARK: - ViewModel

@MainActor
@Observable
final class StatsViewModel {

    private(set) var monthlyData: [MonthlyData] = []
    private(set) var weekdayData: [WeekdayData] = []
    private(set) var trendComparison: TrendComparison?
    private(set) var heatmapDays: [HeatmapDay] = []
    private(set) var totalNoBuyDays: Int = 0
    private(set) var currentStreak: Int = 0
    private(set) var longestStreak: Int = 0
    private(set) var estimatedSavings: Double = 0
    private(set) var totalSpending: Double = 0
    private(set) var hasSpendingData: Bool = false
    var lastError: String?

    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        return cal
    }()

    // MARK: - Compute All Stats

    func compute(from records: [DayRecord], dailySpendingEstimate: Double) {
        do {
            try computeInternal(from: records, dailySpendingEstimate: dailySpendingEstimate)
        } catch {
            AppLogger.data.error("Failed to compute stats: \(error.localizedDescription)")
            lastError = "Could not load statistics. Please try again."
        }
    }

    private func computeInternal(from records: [DayRecord], dailySpendingEstimate: Double) throws {
        let noBuyDates = buildNoBuyDateSet(from: records)
        let allDates = buildAllDateSet(from: records)

        totalNoBuyDays = noBuyDates.count
        estimatedSavings = Double(totalNoBuyDays) * dailySpendingEstimate

        // Compute total spending from records with amounts where user actually spent
        let spendingRecords = records.filter { !$0.isNoBuyDay && $0.amount != nil }
        hasSpendingData = !spendingRecords.isEmpty
        totalSpending = spendingRecords.compactMap(\.amount).reduce(0, +)

        let streakInfo = StreakCalculator.calculate(from: records)
        currentStreak = streakInfo.currentStreak
        longestStreak = streakInfo.longestStreak

        monthlyData = computeMonthlyData(noBuyDates: noBuyDates, allDates: allDates)
        weekdayData = computeWeekdayData(noBuyDates: noBuyDates, allDates: allDates)
        trendComparison = computeTrend(noBuyDates: noBuyDates, allDates: allDates)
        heatmapDays = computeHeatmap(noBuyDates: noBuyDates, allDates: allDates)
        
        // Clear any previous error on success
        lastError = nil
    }

    // MARK: - Helpers

    private func buildNoBuyDateSet(from records: [DayRecord]) -> Set<Date> {
        Set(records.filter(\.isNoBuyDay).map { calendar.startOfDay(for: $0.date) })
    }

    private func buildAllDateSet(from records: [DayRecord]) -> Set<Date> {
        Set(records.map { calendar.startOfDay(for: $0.date) })
    }

    // MARK: - Monthly Data (last 6 months)

    private func computeMonthlyData(noBuyDates: Set<Date>, allDates: Set<Date>) -> [MonthlyData] {
        let today = calendar.startOfDay(for: .now)
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMM"

        return (0..<6).reversed().compactMap { monthsBack -> MonthlyData? in
            guard let monthStart = calendar.date(byAdding: .month, value: -monthsBack, to: today.startOfMonth) else { return nil }
            let range = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<31
            let daysInMonth = monthsBack == 0
                ? (calendar.dateComponents([.day], from: monthStart, to: today).day ?? 0) + 1
                : range.count

            var noBuyCount = 0
            for dayOffset in 0..<daysInMonth {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: monthStart) else { continue }
                let normalized = calendar.startOfDay(for: date)
                if noBuyDates.contains(normalized) {
                    noBuyCount += 1
                }
            }

            return MonthlyData(
                month: monthStart,
                label: formatter.string(from: monthStart).capitalized,
                noBuyCount: noBuyCount,
                totalDays: daysInMonth
            )
        }
    }

    // MARK: - Weekday Distribution

    private func computeWeekdayData(noBuyDates: Set<Date>, allDates: Set<Date>) -> [WeekdayData] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current

        // Monday-first short names
        var symbols = formatter.shortWeekdaySymbols!
        let sunday = symbols.removeFirst()
        symbols.append(sunday)

        // weekday component: 1=Sun, 2=Mon, …, 7=Sat
        // We map to Monday=1 … Sunday=7
        var noBuyCounts = [Int: Int]()
        var totalCounts = [Int: Int]()

        for date in allDates {
            let wd = calendar.component(.weekday, from: date)
            let mondayBased = wd == 1 ? 7 : wd - 1
            totalCounts[mondayBased, default: 0] += 1
            if noBuyDates.contains(date) {
                noBuyCounts[mondayBased, default: 0] += 1
            }
        }

        return (1...7).map { day in
            WeekdayData(
                weekday: day,
                label: symbols[day - 1].capitalized,
                noBuyCount: noBuyCounts[day, default: 0],
                totalRecorded: totalCounts[day, default: 0]
            )
        }
    }

    // MARK: - Month-over-Month Trend

    private func computeTrend(noBuyDates: Set<Date>, allDates: Set<Date>) -> TrendComparison? {
        let today = calendar.startOfDay(for: .now)
        let thisMonthStart = today.startOfMonth

        guard let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart) else { return nil }

        let daysSoFarThisMonth = (calendar.dateComponents([.day], from: thisMonthStart, to: today).day ?? 0) + 1
        let daysInLastMonth = calendar.range(of: .day, in: .month, for: lastMonthStart)?.count ?? 30

        let thisMonthNoBuy = countNoBuyDays(in: thisMonthStart, dayCount: daysSoFarThisMonth, noBuyDates: noBuyDates)
        let lastMonthNoBuy = countNoBuyDays(in: lastMonthStart, dayCount: daysInLastMonth, noBuyDates: noBuyDates)

        let thisPct = daysSoFarThisMonth > 0 ? Double(thisMonthNoBuy) / Double(daysSoFarThisMonth) * 100 : 0
        let lastPct = daysInLastMonth > 0 ? Double(lastMonthNoBuy) / Double(daysInLastMonth) * 100 : 0

        return TrendComparison(
            thisMonthPercentage: thisPct,
            lastMonthPercentage: lastPct,
            thisMonthNoBuy: thisMonthNoBuy,
            thisMonthTotal: daysSoFarThisMonth,
            lastMonthNoBuy: lastMonthNoBuy,
            lastMonthTotal: daysInLastMonth
        )
    }

    private func countNoBuyDays(in monthStart: Date, dayCount: Int, noBuyDates: Set<Date>) -> Int {
        var count = 0
        for offset in 0..<dayCount {
            guard let date = calendar.date(byAdding: .day, value: offset, to: monthStart) else { continue }
            if noBuyDates.contains(calendar.startOfDay(for: date)) {
                count += 1
            }
        }
        return count
    }

    // MARK: - Yearly Heatmap

    private func computeHeatmap(noBuyDates: Set<Date>, allDates: Set<Date>) -> [HeatmapDay] {
        let today = calendar.startOfDay(for: .now)
        guard let yearAgo = calendar.date(byAdding: .year, value: -1, to: today) else { return [] }

        // Start from the Monday of the week containing yearAgo
        let yearAgoWeekday = calendar.component(.weekday, from: yearAgo)
        let mondayBased = yearAgoWeekday == 1 ? 6 : yearAgoWeekday - 2
        guard let startDate = calendar.date(byAdding: .day, value: -mondayBased, to: yearAgo) else { return [] }

        var days: [HeatmapDay] = []
        var current = startDate
        let startWeek = calendar.component(.weekOfYear, from: startDate)

        var weekIndex = 0
        var lastWeekOfYear = calendar.component(.weekOfYear, from: startDate)

        while current <= today {
            let currentWeekOfYear = calendar.component(.weekOfYear, from: current)
            if currentWeekOfYear != lastWeekOfYear {
                weekIndex += 1
                lastWeekOfYear = currentWeekOfYear
            }

            let wd = calendar.component(.weekday, from: current)
            let mondayBasedWd = wd == 1 ? 7 : wd - 1

            let status: HeatmapStatus
            if current > today {
                status = .future
            } else if noBuyDates.contains(current) {
                status = .noBuy
            } else if allDates.contains(current) {
                status = .spent
            } else {
                status = .unrecorded
            }

            days.append(HeatmapDay(
                date: current,
                weekOfYear: weekIndex,
                weekday: mondayBasedWd,
                status: status
            ))

            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return days
    }
}
