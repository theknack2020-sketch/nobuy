import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let status: DayStatus

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var isFuture: Bool {
        date > .now
    }

    var body: some View {
        Text("\(date.dayOfMonth)")
            .font(.system(.body, design: .rounded, weight: isToday ? .bold : .regular))
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isToday ? Color.noBuyGreen : .clear, lineWidth: 2)
            )
    }

    private var foregroundColor: Color {
        switch status {
        case .noBuy:
            return .white
        case .spent:
            return .white
        case .unrecorded:
            return isFuture ? .textTertiary : .textPrimary
        case .future:
            return .textTertiary
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .noBuy:
            return .noBuyGreen
        case .spent:
            return .spendRed
        case .unrecorded:
            return .clear
        case .future:
            return .clear
        }
    }
}

#Preview {
    HStack {
        CalendarDayCell(date: .now, status: .noBuy)
        CalendarDayCell(date: .now, status: .spent)
        CalendarDayCell(date: .now, status: .unrecorded)
        CalendarDayCell(
            date: Calendar.current.date(byAdding: .day, value: 2, to: .now)!,
            status: .future
        )
    }
    .padding()
}
