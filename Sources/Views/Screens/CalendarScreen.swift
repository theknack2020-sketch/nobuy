import SwiftUI
import SwiftData

struct CalendarScreen: View {
    @Query(sort: \DayRecord.date, order: .reverse) private var records: [DayRecord]
    @State private var viewModel = CalendarViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Month navigation
                    monthHeader

                    // Calendar grid
                    calendarGrid

                    // Month summary
                    monthSummary
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(Color.surfacePrimary)
            .navigationTitle("Takvim")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                viewModel.goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.textPrimary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(viewModel.monthTitle)
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Button {
                viewModel.goToNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.canGoForward ? .textPrimary : .textTertiary)
                    .frame(width: 44, height: 44)
            }
            .disabled(!viewModel.canGoForward)
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack(spacing: 4) {
                ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 4) {
                // Offset spacers for first day of month
                ForEach(0..<viewModel.firstDayOffset, id: \.self) { _ in
                    Color.clear
                        .frame(height: 44)
                }

                // Actual days
                ForEach(viewModel.daysInMonth, id: \.self) { date in
                    CalendarDayCell(
                        date: date,
                        status: viewModel.dayStatus(for: date, records: records)
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceSecondary)
        )
    }

    // MARK: - Month Summary

    private var monthSummary: some View {
        let calendar = Calendar.current
        let monthDates = viewModel.daysInMonth
        let today = calendar.startOfDay(for: .now)
        let pastDates = monthDates.filter { calendar.startOfDay(for: $0) <= today }

        let noBuyCount = pastDates.filter { date in
            viewModel.dayStatus(for: date, records: records) == .noBuy
        }.count

        let spentCount = pastDates.filter { date in
            viewModel.dayStatus(for: date, records: records) == .spent
        }.count

        let unrecordedCount = pastDates.count - noBuyCount - spentCount

        return VStack(spacing: 16) {
            HStack {
                Text("Özet")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 12) {
                SummaryPill(
                    icon: "checkmark.circle.fill",
                    count: noBuyCount,
                    label: "Harcamasız",
                    color: .noBuyGreen
                )

                SummaryPill(
                    icon: "xmark.circle.fill",
                    count: spentCount,
                    label: "Harcamalı",
                    color: .spendRed
                )

                SummaryPill(
                    icon: "questionmark.circle",
                    count: unrecordedCount,
                    label: "Kayıtsız",
                    color: .textTertiary
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceSecondary)
        )
    }
}

#Preview {
    CalendarScreen()
        .modelContainer(for: [DayRecord.self, MandatoryCategory.self], inMemory: true)
}
