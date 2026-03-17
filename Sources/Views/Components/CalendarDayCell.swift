import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let status: DayStatus
    var onTap: (() -> Void)?

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var isFuture: Bool {
        Calendar.current.startOfDay(for: date) > Calendar.current.startOfDay(for: .now)
    }

    private var isPast: Bool {
        !isFuture
    }

    var body: some View {
        Button {
            if isPast { onTap?() }
        } label: {
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
        .buttonStyle(.plain)
        .disabled(isFuture)
    }

    private var foregroundColor: Color {
        switch status {
        case .noBuy: return .white
        case .spent: return .white
        case .unrecorded: return isFuture ? .textTertiary : .textPrimary
        case .future: return .textTertiary
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .noBuy: return .noBuyGreen
        case .spent: return .spendRed
        case .unrecorded: return .clear
        case .future: return .clear
        }
    }
}

#Preview {
    HStack {
        CalendarDayCell(date: .now, status: .noBuy)
        CalendarDayCell(date: .now, status: .spent)
        CalendarDayCell(date: .now, status: .unrecorded)
    }
    .padding()
}
