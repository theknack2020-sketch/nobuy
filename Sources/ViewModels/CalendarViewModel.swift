import Foundation
import SwiftData
import Observation

@Observable
final class CalendarViewModel {
    var currentMonth: Date = .now
    var selectedDate: Date?

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
        formatter.locale = Locale(identifier: "tr_TR")
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

        if record.isNoBuyDay {
            return .noBuy
        } else {
            return .spent
        }
    }

    func goToPreviousMonth() {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) else { return }
        currentMonth = newMonth
        HapticManager.selection()
    }

    func goToNextMonth() {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) else { return }
        let today = Calendar.current.startOfDay(for: .now)
        guard newMonth <= today else { return }
        currentMonth = newMonth
        HapticManager.selection()
    }

    var canGoForward: Bool {
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) else { return false }
        return nextMonth <= .now
    }
}

enum DayStatus {
    case noBuy
    case spent
    case unrecorded
    case future

    var color: SwiftUI.Color {
        switch self {
        case .noBuy: return .noBuyGreen
        case .spent: return .spendRed
        case .unrecorded: return .clear
        case .future: return .clear
        }
    }
}

import SwiftUI
