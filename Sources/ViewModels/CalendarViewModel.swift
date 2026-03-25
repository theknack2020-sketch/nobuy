import Foundation
import SwiftData
import SwiftUI
import Observation
import os

@MainActor
@Observable
final class CalendarViewModel {
    var currentMonth: Date = .now
    var selectedDate: Date?
    var lastError: String?

    var monthTitle: String {
        currentMonth.monthYearString
    }

    var daysInMonth: [Date] {
        Calendar.current.datesInMonth(of: currentMonth)
    }

    /// 0 = Sunday offset for the first day of month
    var firstDayOffset: Int {
        let calendar = Calendar.current
        let firstWeekday = calendar.firstWeekdayOfMonth(of: currentMonth)
        // Convert to Monday-first (1=Mon, 7=Sun)
        let mondayBased = firstWeekday == 1 ? 6 : firstWeekday - 2
        return mondayBased
    }

    var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        // Monday-first
        var symbols = formatter.veryShortWeekdaySymbols!
        let sunday = symbols.removeFirst()
        symbols.append(sunday)
        return symbols
    }

    func dayStatus(for date: Date, records: [DayRecord]) -> DayStatus {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: .now)

        guard normalizedDate <= today else { return .future }

        guard let record = records.first(where: {
            calendar.startOfDay(for: $0.date) == normalizedDate
        }) else {
            return .unrecorded
        }

        if record.isFrozen {
            return .frozen
        } else if !record.didSpend {
            return .noBuy
        } else if record.isMandatoryOnly {
            return .essential
        } else {
            return .spent
        }
    }

    func goToPreviousMonth() {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        currentMonth = newMonth
        HapticManager.impact(.light)
    }

    func goToNextMonth() {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) else { return }
        let today = Calendar.current.startOfDay(for: .now)
        guard newMonth <= today else { return }
        currentMonth = newMonth
        HapticManager.impact(.light)
    }

    var canGoForward: Bool {
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) else { return false }
        return nextMonth <= .now
    }

    /// Returns how many months from the current month we are (0 = this month, -1 = last month, etc.)
    func monthsFromCurrent() -> Int {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: .now)
        let components = calendar.dateComponents([.month], from: currentMonth, to: now)
        return -(components.month ?? 0)
    }

    // MARK: - Month Summary Stats

    func monthStats(records: [DayRecord]) -> MonthSummaryStats {
        let calendar = Calendar.current
        let monthDates = daysInMonth
        let today = calendar.startOfDay(for: .now)
        let pastDates = monthDates.filter { calendar.startOfDay(for: $0) <= today }

        var noBuy = 0
        var spent = 0
        var essential = 0
        var frozen = 0

        for date in pastDates {
            switch dayStatus(for: date, records: records) {
            case .noBuy: noBuy += 1
            case .spent: spent += 1
            case .essential: essential += 1
            case .frozen: frozen += 1
            case .unrecorded, .future: break
            }
        }

        let unrecorded = pastDates.count - noBuy - spent - essential - frozen
        let streakPreserved = noBuy + essential + frozen
        let percentage = pastDates.isEmpty ? 0.0 : Double(streakPreserved) / Double(pastDates.count) * 100

        return MonthSummaryStats(
            noBuyCount: noBuy,
            spentCount: spent,
            essentialCount: essential,
            frozenCount: frozen,
            unrecordedCount: unrecorded,
            totalPastDays: pastDates.count,
            streakPreservedPercentage: percentage
        )
    }
}

// MARK: - Month Summary Stats

struct MonthSummaryStats {
    let noBuyCount: Int
    let spentCount: Int
    let essentialCount: Int
    let frozenCount: Int
    let unrecordedCount: Int
    let totalPastDays: Int
    let streakPreservedPercentage: Double
}

enum DayStatus {
    case noBuy
    case spent
    case essential  // mandatory-only spending (streak preserved)
    case frozen
    case unrecorded
    case future

    var color: SwiftUI.Color {
        switch self {
        case .noBuy: return .noBuyGreen
        case .spent: return .spendRed
        case .essential: return .mandatoryAmber
        case .frozen: return .blue.opacity(0.6)
        case .unrecorded: return .clear
        case .future: return .clear
        }
    }
}
