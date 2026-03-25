import SwiftUI
import SwiftData

struct CalendarScreen: View {
    @Query(sort: \DayRecord.date, order: .reverse) private var records: [DayRecord]
    @Environment(StoreService.self) private var store
    @State private var viewModel = CalendarViewModel()
    @State private var selectedDateForEdit: IdentifiableDate?
    @State private var monthTransitionDirection: Edge = .trailing
    @State private var showPaywall = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var summaryAppeared = false
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.xxl) {
                    if records.isEmpty {
                        calendarEmptyState
                    } else {
                        monthHeader
                        calendarGrid
                        legendRow
                        monthSummary
                    }
                }
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.top, DS.Spacing.sm)
                .padding(.bottom, DS.Spacing.xxl)
                .redacted(reason: isLoading ? .placeholder : [])
                .allowsHitTesting(!isLoading)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.surfacePrimary)
            .navigationTitle(L10n.calendarTitle)
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedDateForEdit) { item in
                let calendar = Calendar.current
                let normalized = calendar.startOfDay(for: item.date)
                let existing = records.first { calendar.startOfDay(for: $0.date) == normalized }
                DayEditSheet(date: item.date, existingRecord: existing)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(store: store)
            }
            .onAppear {
                if isLoading {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation { isLoading = false }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var calendarEmptyState: some View {
        VStack(spacing: DS.Spacing.lg) {
            Spacer().frame(height: DS.Spacing.xxxl)

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.noBuyGreen.opacity(0.6))
                .symbolEffect(.pulse, options: reduceMotion ? .nonRepeating : .repeating)
                .accessibilityHidden(true)

            VStack(spacing: DS.Spacing.sm) {
                Text(L10n.emptyCalendarTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.textPrimary)

                Text(L10n.emptyCalendarDesc)
                    .font(.callout)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
            }

            Spacer().frame(height: DS.Spacing.xxxl)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        VStack(spacing: DS.Spacing.sm) {
            HStack {
            Button {
                HapticManager.impact(.light)
                if !store.isPro && viewModel.monthsFromCurrent() <= -1 {
                    // Free users can go back max 1 month
                    showPaywall = true
                } else {
                    monthTransitionDirection = .leading
                    withAnimation(reduceMotion ? nil : DS.Anim.normal) {
                        viewModel.goToPreviousMonth()
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.scale)
            .accessibilityLabel("Previous month")
            .accessibilityHint("Double tap to go to previous month")

            Spacer()

            Text(viewModel.monthTitle)
                .font(.title2)
                .fontWeight(.bold)
                .id(viewModel.monthTitle)
                .transition(.push(from: monthTransitionDirection == .leading ? .leading : .trailing))
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button {
                HapticManager.impact(.light)
                monthTransitionDirection = .trailing
                withAnimation(reduceMotion ? nil : DS.Anim.normal) {
                    viewModel.goToNextMonth()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.canGoForward ? .textPrimary : .textTertiary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.scale)
            .disabled(!viewModel.canGoForward)
            .accessibilityLabel("Next month")
            .accessibilityHint("Double tap to go to next month")
            }

            // Gradient accent line
            RoundedRectangle(cornerRadius: 1.5)
                .fill(
                    LinearGradient(
                        colors: [.noBuyGreen.opacity(0.5), .noBuyGreen.opacity(0.1), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .padding(.horizontal, DS.Spacing.xl)
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: DS.Spacing.sm) {
            HStack(spacing: DS.Spacing.xs) {
                ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.xs), count: 7)
            LazyVGrid(columns: columns, spacing: DS.Spacing.xs) {
                ForEach(0..<viewModel.firstDayOffset, id: \.self) { _ in
                    Color.clear.frame(height: 44)
                }

                ForEach(viewModel.daysInMonth, id: \.self) { date in
                    CalendarDayCell(
                        date: date,
                        status: viewModel.dayStatus(for: date, records: records)
                    ) {
                        HapticManager.impact(.light)
                        selectedDateForEdit = IdentifiableDate(date: date)
                    }
                }
            }
            .id(viewModel.monthTitle)
            .transition(.push(from: monthTransitionDirection == .leading ? .leading : .trailing))
        }
        .padding(DS.Spacing.lg)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg)
                .fill(Color.surfaceSecondary)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.width > 50 {
                        HapticManager.impact(.light)
                        if !store.isPro && viewModel.monthsFromCurrent() <= -1 {
                            showPaywall = true
                        } else {
                            monthTransitionDirection = .leading
                            withAnimation(reduceMotion ? nil : DS.Anim.normal) {
                                viewModel.goToPreviousMonth()
                            }
                        }
                    } else if value.translation.width < -50 && viewModel.canGoForward {
                        HapticManager.impact(.light)
                        monthTransitionDirection = .trailing
                        withAnimation(reduceMotion ? nil : DS.Anim.normal) {
                            viewModel.goToNextMonth()
                        }
                    }
                }
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Calendar for \(viewModel.monthTitle)")
    }

    // MARK: - Legend Row

    private var legendRow: some View {
        HStack(spacing: DS.Spacing.lg) {
            legendItem(color: .noBuyGreen, label: L10n.noBuyDays)
            legendItem(color: .spendRed, label: L10n.spentDays)
            legendItem(color: .mandatoryAmber, label: "Essential")
            legendItem(color: .blue.opacity(0.6), label: "Freeze")
        }
        .font(.caption2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Legend: green for no-spend days, red for spent days, amber for essential, blue for freeze")
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: DS.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(label)
                .foregroundStyle(.textSecondary)
        }
    }

    // MARK: - Month Summary

    private var monthSummary: some View {
        let stats = viewModel.monthStats(records: records)

        return VStack(spacing: DS.Spacing.lg) {
            // Header with percentage
            HStack {
                Text(L10n.summary)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(Int(stats.streakPreservedPercentage))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.noBuyGreen)
                    .contentTransition(.numericText())
            }
            .opacity(summaryAppeared ? 1 : 0)
            .offset(y: summaryAppeared ? 0 : 10)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.surfaceTertiary)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.noBuyGreen)
                        .frame(
                            width: geo.size.width * stats.streakPreservedPercentage / 100,
                            height: 8
                        )
                        .animation(reduceMotion ? nil : .spring(duration: 0.5), value: stats.streakPreservedPercentage)
                }
            }
            .frame(height: 8)
            .opacity(summaryAppeared ? 1 : 0)
            .accessibilityHidden(true)

            // Stat pills grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: DS.Spacing.sm),
                GridItem(.flexible(), spacing: DS.Spacing.sm),
            ], spacing: DS.Spacing.sm) {
                SummaryPill(icon: "checkmark.circle.fill", count: stats.noBuyCount, label: L10n.noBuyDays, color: .noBuyGreen)
                SummaryPill(icon: "xmark.circle.fill", count: stats.spentCount, label: L10n.spentDays, color: .spendRed)
                SummaryPill(icon: "building.columns.fill", count: stats.essentialCount, label: "Essential", color: .mandatoryAmber)
                SummaryPill(icon: "shield.fill", count: stats.frozenCount, label: "Freeze", color: .blue)
            }
            .opacity(summaryAppeared ? 1 : 0)
            .offset(y: summaryAppeared ? 0 : 10)

            // Unrecorded days note
            if stats.unrecordedCount > 0 {
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: "questionmark.circle")
                        .font(.caption2)
                        .foregroundStyle(.textTertiary)
                    Text("\(stats.unrecordedCount) \(L10n.unrecordedDays.lowercased()) days")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                }
                .opacity(summaryAppeared ? 1 : 0)
            }
        }
        .padding(DS.Spacing.xl)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg)
                .fill(Color.surfaceSecondary)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .onAppear {
            if reduceMotion {
                summaryAppeared = true
            } else {
                withAnimation(DS.Anim.normal.delay(0.2)) {
                    summaryAppeared = true
                }
            }
        }
    }
}

struct IdentifiableDate: Identifiable {
    let date: Date
    var id: TimeInterval { date.timeIntervalSince1970 }
}

#Preview {
    CalendarScreen()
        .environment(StoreService.shared)
        .modelContainer(for: [DayRecord.self, MandatoryCategory.self], inMemory: true)
}
