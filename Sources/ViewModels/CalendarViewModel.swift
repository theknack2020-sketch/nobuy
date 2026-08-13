import Foundation
import Observation
import os
import SwiftData
import SwiftUI

@MainActor
@Observable
final class CalendarViewModel {
    /// Always the first instant of its month — see `startOfMonth` below for why a stray
    /// time-of-day component stranded the user in the past.
    var currentMonth: Date = CalendarViewModel.startOfMonth(.now)
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
        return firstWeekday == 1 ? 6 : firstWeekday - 2
    }

    var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        // Monday-first
        var symbols = formatter.veryShortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
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

    // MARK: - Stepping
    //
    // Every month is held at the START of its month, and the forward bound is one expression used
    // by BOTH the stepper and the chevron's enabled state.
    //
    // The first version kept whatever time of day `.now` carried. Step back once from 01:00 and
    // the next month lands at 01:00 too, which is later than `startOfDay(.now)` — so the guard
    // refused while the chevron, comparing against a different bound, still looked available. The
    // user was stranded in the past until relaunch, pressing a control that did nothing.

    private static func startOfMonth(_ date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    /// The furthest month that may be shown: the one we are living in.
    private var forwardBound: Date { Self.startOfMonth(.now) }

    func goToPreviousMonth() {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        currentMonth = Self.startOfMonth(newMonth)
        HapticManager.impact(.light)
    }

    func goToNextMonth() {
        guard canGoForward,
              let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)
        else { return }
        currentMonth = Self.startOfMonth(newMonth)
        HapticManager.impact(.light)
    }

    var canGoForward: Bool {
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) else { return false }
        return Self.startOfMonth(nextMonth) <= forwardBound
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
    case essential // mandatory-only spending (streak preserved)
    case frozen
    case unrecorded
    case future

    var color: SwiftUI.Color {
        switch self {
        case .noBuy: .accentKept
        case .spent: .accentSpentMark
        case .essential, .frozen: .stateWait
        case .unrecorded: .stateNotYet
        case .future: .clear
        }
    }

    /// The drawn truth for this status. `future` has none — a day that has not happened is not
    /// a state to judge, and the calendar gives it a bare numeral instead of a cell.
    var truth: DayTruth? {
        switch self {
        case .noBuy: .kept
        case .spent: .spent
        case .essential: .mandatoryOnly
        case .frozen: .frozen
        case .unrecorded: .notYet
        case .future: nil
        }
    }
}
