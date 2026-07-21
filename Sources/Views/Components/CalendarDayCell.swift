import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let status: DayStatus
    var onTap: (() -> Void)?
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

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
            if isPast {
                HapticManager.tap()
                onTap?()
            }
        } label: {
            ZStack {
                // Day number
                Text("\(date.dayOfMonth)")
                    .font(.system(.body, design: .rounded, weight: isToday ? .bold : .regular))
                    .foregroundStyle(foregroundColor)

                // Status indicator overlay — top-right corner
                statusIndicator
                    .offset(x: 12, y: -12)

                // Bottom dot indicator for colorblind-friendliness
                if status != .unrecorded, status != .future {
                    Circle()
                        .fill(statusDotColor)
                        .frame(width: 5, height: 5)
                        .offset(y: 14)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.15), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .shadow(color: statusShadowColor, radius: status == .unrecorded || status == .future ? 0 : 3, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(todayBorderColor, lineWidth: isToday ? 2.5 : 0)
            )
            .shadow(
                color: isToday ? .noBuyGreen.opacity(0.35) : .clear,
                radius: isToday ? 6 : 0,
                x: 0,
                y: isToday ? 2 : 0
            )
        }
        .buttonStyle(.scale(0.9))
        .disabled(isFuture)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(isPast ? "Double-tap to edit" : "")
    }

    // MARK: - Status Indicator

    @ViewBuilder
    private var statusIndicator: some View {
        switch status {
        case .noBuy:
            Image(systemName: "checkmark.circle.fill")
                .font(Font.adaptiveBadge(isRegular: isRegular))
                .foregroundStyle(.white)
                .shadow(color: .noBuyGreen.opacity(0.5), radius: 1, x: 0, y: 1)
                .accessibilityHidden(true)
        case .spent:
            Image(systemName: "xmark.circle.fill")
                .font(Font.adaptiveBadge(isRegular: isRegular))
                .foregroundStyle(.white)
                .shadow(color: .spendRed.opacity(0.5), radius: 1, x: 0, y: 1)
                .accessibilityHidden(true)
        case .essential:
            Image(systemName: "building.columns.circle.fill")
                .font(Font.adaptiveBadge(isRegular: isRegular))
                .foregroundStyle(.white)
                .shadow(color: .mandatoryAmber.opacity(0.5), radius: 1, x: 0, y: 1)
                .accessibilityHidden(true)
        case .frozen:
            Image(systemName: "shield.fill")
                .font(Font.adaptiveBadge(isRegular: isRegular))
                .foregroundStyle(.white)
                .shadow(color: .blue.opacity(0.5), radius: 1, x: 0, y: 1)
                .accessibilityHidden(true)
        case .unrecorded, .future:
            EmptyView()
        }
    }

    // MARK: - Colors

    private var foregroundColor: Color {
        switch status {
        case .noBuy: .white
        case .spent: .white
        case .essential: .white
        case .frozen: .white
        case .unrecorded: isFuture ? .textTertiary : .textPrimary
        case .future: .textTertiary
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .noBuy: .noBuyGreen
        case .spent: .spendRed
        case .essential: .mandatoryAmber
        case .frozen: .freezeBlue
        case .unrecorded: .clear
        case .future: .clear
        }
    }

    private var statusShadowColor: Color {
        switch status {
        case .noBuy: .noBuyGreen.opacity(0.3)
        case .spent: .spendRed.opacity(0.25)
        case .essential: .mandatoryAmber.opacity(0.25)
        case .frozen: .blue.opacity(0.2)
        case .unrecorded: .clear
        case .future: .clear
        }
    }

    private var statusDotColor: Color {
        switch status {
        case .noBuy: .white.opacity(0.8)
        case .spent: .white.opacity(0.8)
        case .essential: .white.opacity(0.8)
        case .frozen: .white.opacity(0.8)
        case .unrecorded: .clear
        case .future: .clear
        }
    }

    private var todayBorderColor: Color {
        if !isToday { return .clear }
        switch status {
        case .noBuy: return .white.opacity(0.6)
        case .spent: return .white.opacity(0.6)
        case .essential: return .white.opacity(0.6)
        case .frozen: return .white.opacity(0.6)
        case .unrecorded, .future: return .noBuyGreen
        }
    }

    private var accessibilityText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "d MMMM"
        let dateStr = formatter.string(from: date)

        switch status {
        case .noBuy:
            return "\(dateStr), no-spend day"
        case .spent:
            return "\(dateStr), spent"
        case .essential:
            return "\(dateStr), essential spending only"
        case .frozen:
            return "\(dateStr), freeze used"
        case .unrecorded:
            return "\(dateStr), no record"
        case .future:
            return "\(dateStr), future"
        }
    }
}

#Preview {
    HStack {
        CalendarDayCell(date: .now, status: .noBuy)
        CalendarDayCell(date: .now, status: .spent)
        CalendarDayCell(date: .now, status: .essential)
        CalendarDayCell(date: .now, status: .frozen)
        CalendarDayCell(date: .now, status: .unrecorded)
    }
    .padding()
}
