import SwiftUI
import SwiftData

struct CalendarScreen: View {
    @Query(sort: \DayRecord.date, order: .reverse) private var records: [DayRecord]
    @State private var viewModel = CalendarViewModel()
    @State private var selectedDateForEdit: Date?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    monthHeader
                    calendarGrid
                    monthSummary
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(Color.surfacePrimary)
            .navigationTitle(L10n.calendarTitle)
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedDateForEdit) { date in
                let calendar = Calendar.current
                let normalized = calendar.startOfDay(for: date)
                let existing = records.first { calendar.startOfDay(for: $0.date) == normalized }
                DayEditSheet(date: date, existingRecord: existing)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
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
            HStack(spacing: 4) {
                ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<viewModel.firstDayOffset, id: \.self) { _ in
                    Color.clear.frame(height: 44)
                }

                ForEach(viewModel.daysInMonth, id: \.self) { date in
                    CalendarDayCell(
                        date: date,
                        status: viewModel.dayStatus(for: date, records: records)
                    ) {
                        selectedDateForEdit = date
                    }
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
                Text(L10n.summary)
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 12) {
                SummaryPill(icon: "checkmark.circle.fill", count: noBuyCount, label: L10n.noBuyDays, color: .noBuyGreen)
                SummaryPill(icon: "xmark.circle.fill", count: spentCount, label: L10n.spentDays, color: .spendRed)
                SummaryPill(icon: "questionmark.circle", count: unrecordedCount, label: L10n.unrecordedDays, color: .textTertiary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceSecondary)
        )
    }
}

// Make Date identifiable for sheet binding
extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

#Preview {
    CalendarScreen()
        .modelContainer(for: [DayRecord.self, MandatoryCategory.self], inMemory: true)
}
