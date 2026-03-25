import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    var endOfMonth: Date {
        let calendar = Calendar.current
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { return self }
        return calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? self
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var dayOfMonth: Int {
        Calendar.current.component(.day, from: self)
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self).capitalized
    }

    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEE"
        return formatter.string(from: self).uppercased()
    }
}

extension Calendar {
    func datesInMonth(of date: Date) -> [Date] {
        guard let range = self.range(of: .day, in: .month, for: date) else { return [] }
        let startOfMonth = self.date(from: self.dateComponents([.year, .month], from: date))!
        return range.compactMap { day in
            self.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }

    func firstWeekdayOfMonth(of date: Date) -> Int {
        let startOfMonth = self.date(from: self.dateComponents([.year, .month], from: date))!
        return self.component(.weekday, from: startOfMonth)
    }
}
