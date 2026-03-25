import SwiftUI
import SwiftData
import Charts

// MARK: - Chart Data Types

private struct MonthlyBarEntry: Identifiable {
    let id = UUID()
    let month: String
    let category: String
    let count: Int
}

private struct WeekStreakPoint: Identifiable {
    let id = UUID()
    let weekIndex: Int
    let weekLabel: String
    let streakLength: Int
}

private struct CategorySlice: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
}

private struct NoBuyRatePoint: Identifiable {
    let id = UUID()
    let label: String
    let month: Date
    let rate: Double
}

// MARK: - Stats Screen

struct StatsScreen: View {
    @Query(sort: \DayRecord.date, order: .reverse) private var records: [DayRecord]
    @Environment(StoreService.self) private var store
    @Environment(AchievementManager.self) private var achievementManager
    @AppStorage("dailySpendingEstimate") private var dailySpendingEstimate: Double = 0

    @State private var viewModel = StatsViewModel()
    @State private var showPaywall = false
    @State private var appeared = false
    @State private var isLoading = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var noBuyRecords: [DayRecord] { records.filter { $0.isNoBuyDay } }

    // MARK: - Computed Chart Data

    private var monthlyBarEntries: [MonthlyBarEntry] {
        viewModel.monthlyData.flatMap { item in [
            MonthlyBarEntry(month: item.label, category: "No-Spend", count: item.noBuyCount),
            MonthlyBarEntry(month: item.label, category: "Spent", count: max(0, item.totalDays - item.noBuyCount))
        ]}
    }

    private var weeklyStreakPoints: [WeekStreakPoint] {
        let calendar: Calendar = {
            var cal = Calendar.current
            cal.firstWeekday = 2
            return cal
        }()
        let today = calendar.startOfDay(for: .now)
        let noBuyDates = Set(records.filter(\.isNoBuyDay).map { calendar.startOfDay(for: $0.date) })
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        var results: [WeekStreakPoint] = []
        for weekBack in (0..<12).reversed() {
            guard let weekEndDate = calendar.date(byAdding: .day, value: -weekBack * 7, to: today) else { continue }
            let normalizedEnd = calendar.startOfDay(for: weekEndDate)

            var streak = 0
            var checkDate = normalizedEnd
            while noBuyDates.contains(checkDate) {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            }

            results.append(WeekStreakPoint(
                weekIndex: 12 - weekBack,
                weekLabel: formatter.string(from: normalizedEnd),
                streakLength: streak
            ))
        }
        return results
    }

    private var categorySlices: [CategorySlice] {
        var noSpend = 0
        var essential = 0
        var discretionary = 0

        for record in records {
            if record.isFrozen || !record.didSpend {
                noSpend += 1
            } else if record.isMandatoryOnly {
                essential += 1
            } else {
                discretionary += 1
            }
        }

        var slices: [CategorySlice] = []
        if noSpend > 0 { slices.append(.init(category: "No-Spend", count: noSpend)) }
        if essential > 0 { slices.append(.init(category: "Essential", count: essential)) }
        if discretionary > 0 { slices.append(.init(category: "Discretionary", count: discretionary)) }
        return slices
    }

    private var noBuyRatePoints: [NoBuyRatePoint] {
        viewModel.monthlyData.map { item in
            NoBuyRatePoint(
                label: item.label,
                month: item.month,
                rate: item.percentage
            )
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.xxl) {
                    if records.isEmpty {
                        statsEmptyState
                    } else {
                        overviewCards
                    }

                    if store.isPro {
                        // Savings Estimate (Pro)
                        savingsEstimateCard
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 4), value: appeared)

                        // Monthly Trend — stacked bar (Pro)
                        monthlyTrendChart
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 5), value: appeared)

                        // Weekly Distribution (Pro)
                        weekdayChart
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 6), value: appeared)

                        // Streak History — line chart (Pro)
                        streakHistoryChart
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 7), value: appeared)

                        // Category Breakdown — pie chart (Pro)
                        categoryBreakdownChart
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 8), value: appeared)

                        // No-Spend Rate — area chart (Pro)
                        noBuyRateChart
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 9), value: appeared)

                        // Trend Comparison (Pro)
                        trendComparison
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 10), value: appeared)

                        // Calendar Heatmap (Pro)
                        calendarHeatmap
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 11), value: appeared)
                    } else {
                        proTeaser
                            .offset(y: appeared ? 0 : 20)
                            .opacity(appeared ? 1 : 0)
                            .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 4), value: appeared)
                    }

                    // Achievements — first 5 free, full list for Pro
                    achievementsGrid
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 12), value: appeared)

                    // Impulse control stats — visible to ALL users (free + Pro)
                    impulseControlStats
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 13), value: appeared)

                    // Waiting list stats — visible to ALL users
                    waitingListStats
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 14), value: appeared)
                }
                .padding(.horizontal, DS.Spacing.xl)
                .padding(.top, DS.Spacing.sm)
                .padding(.bottom, DS.Spacing.xxxl)
                .redacted(reason: isLoading ? .placeholder : [])
                .allowsHitTesting(!isLoading)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.surfacePrimary)
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(store: store)
        }
        .onAppear {
            refreshStats()
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    appeared = true
                }
            }
            if isLoading {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation { isLoading = false }
                }
            }
        }
        .onChange(of: records.count) { refreshStats() }
    }

    private func refreshStats() {
        viewModel.compute(from: records, dailySpendingEstimate: dailySpendingEstimate)
    }

    // MARK: - Overview Cards (2×2 Grid)

    private var overviewCards: some View {
        VStack(spacing: DS.Spacing.md) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: DS.Spacing.md),
                GridItem(.flexible(), spacing: DS.Spacing.md)
            ], spacing: DS.Spacing.md) {
                statCard(
                    title: "Total Days",
                    value: "\(viewModel.totalNoBuyDays)",
                    icon: "checkmark.circle.fill",
                    color: .noBuyGreen
                )
                .accessibilityLabel("Total no-spend days: \(viewModel.totalNoBuyDays)")
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)
                .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 0), value: appeared)

                statCard(
                    title: "Estimated Savings",
                    value: formattedSavings,
                    icon: "turkishlirasign.circle.fill",
                    color: .noBuyGreen
                )
                .accessibilityLabel("Estimated savings: \(formattedSavings)")
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)
                .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 1), value: appeared)

                statCard(
                    title: "Current Streak",
                    value: "\(viewModel.currentStreak)",
                    subtitle: "days",
                    icon: "flame.fill",
                    color: .orange
                )
                .accessibilityLabel("Current streak: \(viewModel.currentStreak) days")
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)
                .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 2), value: appeared)

                statCard(
                    title: "Longest Streak",
                    value: "\(viewModel.longestStreak)",
                    subtitle: "days",
                    icon: "trophy.fill",
                    color: .yellow
                )
                .accessibilityLabel("Longest streak: \(viewModel.longestStreak) days")
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)
                .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 3), value: appeared)
            }

            // Total spending card (only if any records have amounts)
            if viewModel.hasSpendingData {
                statCard(
                    title: "Total Spending",
                    value: formattedTotalSpending,
                    icon: "creditcard.fill",
                    color: .spendRed
                )
                .accessibilityLabel("Total spending: \(formattedTotalSpending)")
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)
                .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 3.5), value: appeared)
            }
        }
    }

    private var formattedSavings: String {
        let amount = viewModel.estimatedSavings
        if amount == 0 { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }

    private var formattedTotalSpending: String {
        let amount = viewModel.totalSpending
        if amount == 0 { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }

    private func statCard(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.xs) {
                Text(value)
                    .font(.title.bold())
                    .foregroundStyle(.textPrimary)
                    .contentTransition(.numericText())
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.lg)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .background(Color.surfaceSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }

    // MARK: - Savings Estimate Card (Pro)

    private var savingsEstimateCard: some View {
        VStack(spacing: DS.Spacing.lg) {
            sectionHeader(
                title: "Savings Estimate",
                icon: "banknote.fill",
                showProBadge: true
            )

            if dailySpendingEstimate > 0 {
                VStack(spacing: DS.Spacing.sm) {
                    Text(formattedSavings)
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(.noBuyGreen)
                        .contentTransition(.numericText())
                        .animation(reduceMotion ? nil : DS.Anim.normal, value: viewModel.estimatedSavings)

                    Text("\(viewModel.totalNoBuyDays) no-spend days × \(formattedDailyEstimate)/day")
                        .font(.subheadline)
                        .foregroundStyle(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.md)
            } else {
                VStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundStyle(.textTertiary)
                    Text("Set your daily spending estimate in Settings to see savings")
                        .font(.subheadline)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, DS.Spacing.md)
            }
        }
        .sectionCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Savings estimate: \(formattedSavings). \(viewModel.totalNoBuyDays) no-spend days.")
    }

    private var formattedDailyEstimate: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: dailySpendingEstimate)) ?? "$\(Int(dailySpendingEstimate))"
    }

    // MARK: - Monthly Trend Bar Chart (Stacked — Pro)

    private var monthlyTrendChart: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            sectionHeader(
                title: "Monthly Trend",
                icon: "chart.bar.fill",
                showProBadge: true
            )

            Chart(monthlyBarEntries) { entry in
                BarMark(
                    x: .value("Month", entry.month),
                    y: .value("Days", entry.count)
                )
                .foregroundStyle(by: .value("Category", entry.category))
                .cornerRadius(DS.Radius.sm / 2)
            }
            .chartForegroundStyleScale([
                "No-Spend": Color.noBuyGreen,
                "Spent": Color.spendRed
            ])
            .chartLegend(position: .bottom, alignment: .center, spacing: DS.Spacing.md)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(Color.textTertiary.opacity(0.3))
                    AxisValueLabel()
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .frame(height: 220)
        }
        .sectionCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Monthly trend chart showing no-spend versus spend days for the last 6 months")
    }

    // MARK: - Weekday Distribution Chart (Pro)

    private var weekdayChart: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            sectionHeader(
                title: "Weekly Distribution",
                icon: "calendar.day.timeline.left",
                showProBadge: true
            )

            Chart(viewModel.weekdayData) { item in
                BarMark(
                    x: .value("Count", item.noBuyCount),
                    y: .value("Day", item.label)
                )
                .foregroundStyle(barColor(for: item).gradient)
                .cornerRadius(DS.Radius.sm / 2)
                .annotation(position: .trailing, spacing: 4) {
                    if item.totalRecorded > 0 {
                        Text("\(Int(item.percentage))%")
                            .font(.caption2)
                            .foregroundStyle(.textTertiary)
                    }
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .frame(height: 210)
        }
        .sectionCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly distribution chart showing which days of the week have the most no-spend days")
    }

    private func barColor(for item: WeekdayData) -> Color {
        if item.percentage >= 70 { return .noBuyGreen }
        if item.percentage >= 40 { return .mandatoryAmber }
        return .spendRed
    }

    // MARK: - Streak History Line Chart (Pro)

    private var streakHistoryChart: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            sectionHeader(
                title: "Streak History",
                icon: "chart.xyaxis.line",
                showProBadge: true
            )

            if weeklyStreakPoints.isEmpty || weeklyStreakPoints.allSatisfy({ $0.streakLength == 0 }) {
                Text("Start building streaks to see your history")
                    .font(.subheadline)
                    .foregroundStyle(.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DS.Spacing.xl)
            } else {
                Chart(weeklyStreakPoints) { point in
                    AreaMark(
                        x: .value("Week", point.weekLabel),
                        y: .value("Streak", point.streakLength)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.noBuyGreen.opacity(0.3), Color.noBuyGreen.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Week", point.weekLabel),
                        y: .value("Streak", point.streakLength)
                    )
                    .foregroundStyle(Color.noBuyGreen)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Week", point.weekLabel),
                        y: .value("Streak", point.streakLength)
                    )
                    .foregroundStyle(Color.noBuyGreen)
                    .symbolSize(36)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(Color.textTertiary.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.textSecondary)
                            .font(.caption2)
                    }
                }
                .frame(height: 200)
            }
        }
        .sectionCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Streak history chart showing streak lengths over the last 12 weeks. Current streak: \(viewModel.currentStreak) days.")
    }

    // MARK: - Category Breakdown Pie Chart (Pro)

    private var categoryBreakdownChart: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            sectionHeader(
                title: "Day Breakdown",
                icon: "chart.pie.fill",
                showProBadge: true
            )

            if categorySlices.isEmpty {
                Text("No data yet")
                    .font(.subheadline)
                    .foregroundStyle(.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DS.Spacing.xl)
            } else {
                HStack(spacing: DS.Spacing.xl) {
                    Chart(categorySlices) { slice in
                        SectorMark(
                            angle: .value("Count", slice.count),
                            innerRadius: .ratio(0.618),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Category", slice.category))
                        .cornerRadius(DS.Radius.sm / 2)
                    }
                    .chartForegroundStyleScale([
                        "No-Spend": Color.noBuyGreen,
                        "Essential": Color.mandatoryAmber,
                        "Discretionary": Color.spendRed
                    ])
                    .chartLegend(.hidden)
                    .frame(width: 140, height: 140)

                    // Legend with counts
                    VStack(alignment: .leading, spacing: DS.Spacing.md) {
                        ForEach(categorySlices) { slice in
                            HStack(spacing: DS.Spacing.sm) {
                                Circle()
                                    .fill(colorForCategory(slice.category))
                                    .frame(width: 10, height: 10)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(slice.category)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.textPrimary)
                                    Text("\(slice.count) days")
                                        .font(.caption2)
                                        .foregroundStyle(.textSecondary)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.sm)
            }
        }
        .sectionCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Day breakdown pie chart. \(categorySlices.map { "\($0.count) \($0.category) days" }.joined(separator: ", ")).")
    }

    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "No-Spend": return .noBuyGreen
        case "Essential": return .mandatoryAmber
        case "Discretionary": return .spendRed
        default: return .textTertiary
        }
    }

    // MARK: - No-Spend Rate Area Chart (Pro)

    private var noBuyRateChart: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            sectionHeader(
                title: "No-Spend Rate",
                icon: "percent",
                showProBadge: true
            )

            if noBuyRatePoints.isEmpty {
                Text("Not enough data yet")
                    .font(.subheadline)
                    .foregroundStyle(.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DS.Spacing.xl)
            } else {
                Chart(noBuyRatePoints) { point in
                    AreaMark(
                        x: .value("Month", point.label),
                        y: .value("Rate", point.rate)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.noBuyGreen.opacity(0.4), Color.noBuyGreen.opacity(0.03)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Month", point.label),
                        y: .value("Rate", point.rate)
                    )
                    .foregroundStyle(Color.noBuyGreen.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Month", point.label),
                        y: .value("Rate", point.rate)
                    )
                    .foregroundStyle(Color.noBuyGreen)
                    .symbolSize(30)
                    .annotation(position: .top, spacing: 4) {
                        if point.rate > 0 {
                            Text(String(format: "%.0f%%", point.rate))
                                .font(.caption2.bold())
                                .foregroundStyle(.textSecondary)
                        }
                    }
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(Color.textTertiary.opacity(0.3))
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text("\(v)%")
                                    .font(.caption2)
                                    .foregroundStyle(Color.textTertiary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .frame(height: 200)
            }
        }
        .sectionCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No-spend rate trend chart showing monthly percentage of no-spend days")
    }

    // MARK: - Trend Comparison

    private var trendComparison: some View {
        Group {
            if let trend = viewModel.trendComparison {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    sectionHeader(
                        title: "Monthly Comparison",
                        icon: "arrow.triangle.swap",
                        showProBadge: true
                    )

                    HStack(spacing: DS.Spacing.xl) {
                        trendColumn(
                            label: "This Month",
                            percentage: trend.thisMonthPercentage,
                            detail: "\(trend.thisMonthNoBuy)/\(trend.thisMonthTotal) days",
                            isPrimary: true
                        )

                        VStack(spacing: DS.Spacing.xs) {
                            Image(systemName: trend.isImproving ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .font(.title)
                                .foregroundStyle(trend.isImproving ? Color.noBuyGreen : Color.spendRed)
                                .symbolEffect(.bounce, value: trend.delta)

                            Text(String(format: "%+.0f%%", trend.delta))
                                .font(.caption.bold())
                                .foregroundStyle(trend.isImproving ? Color.noBuyGreen : Color.spendRed)
                        }

                        trendColumn(
                            label: "Last Month",
                            percentage: trend.lastMonthPercentage,
                            detail: "\(trend.lastMonthNoBuy)/\(trend.lastMonthTotal) days",
                            isPrimary: false
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .sectionCard()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Monthly comparison. This month: \(String(format: "%.0f", trend.thisMonthPercentage)) percent. Last month: \(String(format: "%.0f", trend.lastMonthPercentage)) percent. \(trend.isImproving ? "Improving" : "Declining").")
            }
        }
    }

    private func trendColumn(label: String, percentage: Double, detail: String, isPrimary: Bool) -> some View {
        VStack(spacing: DS.Spacing.sm) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.textSecondary)

            Text(String(format: "%.0f%%", percentage))
                .font(.title2.bold())
                .foregroundStyle(isPrimary ? Color.textPrimary : Color.textSecondary)

            Text(detail)
                .font(.caption2)
                .foregroundStyle(.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Calendar Heatmap

    private var calendarHeatmap: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            sectionHeader(
                title: "Yearly Overview",
                icon: "square.grid.3x3.fill",
                showProBadge: true
            )

            if viewModel.heatmapDays.isEmpty {
                Text("No data yet")
                    .font(.subheadline)
                    .foregroundStyle(.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DS.Spacing.xl)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    heatmapGrid
                }
            }

            HStack(spacing: DS.Spacing.lg) {
                heatmapLegendItem(color: Color.noBuyGreen, label: "No-Spend")
                heatmapLegendItem(color: Color.spendRed, label: "Spent")
                heatmapLegendItem(color: Color.surfaceTertiary, label: "Unrecorded")
            }
            .font(.caption2)
        }
        .sectionCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Yearly overview calendar heatmap showing daily spending patterns")
    }

    private var heatmapGrid: some View {
        let cellSize: CGFloat = 12
        let spacing: CGFloat = 3

        let maxWeek = viewModel.heatmapDays.map(\.weekOfYear).max() ?? 0

        return Canvas { context, _ in
            for day in viewModel.heatmapDays {
                let x = CGFloat(day.weekOfYear) * (cellSize + spacing)
                let y = CGFloat(day.weekday - 1) * (cellSize + spacing)
                let rect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                let path = RoundedRectangle(cornerRadius: 2).path(in: rect)

                let color: Color = switch day.status {
                case .noBuy: .noBuyGreen
                case .spent: .spendRed
                case .unrecorded: .surfaceTertiary
                case .future: .clear
                }

                context.fill(path, with: .color(color))
            }
        }
        .frame(
            width: CGFloat(maxWeek + 1) * (cellSize + spacing),
            height: 7 * (cellSize + spacing)
        )
    }

    private func heatmapLegendItem(color: Color, label: String) -> some View {
        HStack(spacing: DS.Spacing.xs) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .foregroundStyle(.textTertiary)
        }
    }

    // MARK: - Achievements Grid

    private var achievementsGrid: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            sectionHeader(
                title: "Achievements",
                icon: "medal.fill",
                showProBadge: !store.isPro
            )

            let allAchievements = achievementManager.achievements
            let unlockedCount = allAchievements.filter(\.isUnlocked).count
            let totalCount = allAchievements.count
            let freeLimit = 5

            Text("\(unlockedCount)/\(totalCount) achievements unlocked")
                .font(.caption)
                .foregroundStyle(.textSecondary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: DS.Spacing.md),
                GridItem(.flexible(), spacing: DS.Spacing.md),
                GridItem(.flexible(), spacing: DS.Spacing.md)
            ], spacing: DS.Spacing.md) {
                ForEach(Array(allAchievements.enumerated()), id: \.element.id) { index, achievement in
                    if store.isPro || index < freeLimit {
                        achievementCell(achievement)
                    } else {
                        lockedAchievementCell(achievement)
                    }
                }
            }

            // Upgrade prompt for free users
            if !store.isPro && allAchievements.count > freeLimit {
                Button {
                    HapticManager.impact(.medium)
                    showPaywall = true
                } label: {
                    HStack(spacing: DS.Spacing.sm) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                        Text("Unlock all \(totalCount) achievements with Pro")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.noBuyGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .fill(Color.noBuyGreenLight)
                    )
                }
                .buttonStyle(.scale)
                .accessibilityLabel("Unlock all achievements with Pro")
            }
        }
        .sectionCard()
    }

    private func lockedAchievementCell(_ achievement: Achievement) -> some View {
        VStack(spacing: DS.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.surfaceTertiary)
                    .frame(width: 52, height: 52)

                Text("🔒")
                    .font(.title3)
            }

            Text(achievement.title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(0.4)
    }

    private func achievementCell(_ achievement: Achievement) -> some View {
        VStack(spacing: DS.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked
                          ? Color.noBuyGreen.opacity(0.15)
                          : Color.surfaceTertiary)
                    .frame(width: 52, height: 52)

                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundStyle(achievement.isUnlocked ? Color.noBuyGreen : Color.textTertiary)
            }

            Text(achievement.title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(achievement.isUnlocked ? Color.textPrimary : Color.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(achievement.isUnlocked ? 1 : 0.5)
        .grayscale(achievement.isUnlocked ? 0 : 0.8)
    }

    // MARK: - Impulse Control Stats (Free + Pro)

    private var impulseControlStats: some View {
        let checklistCompletions = UserDefaults.standard.integer(forKey: "impulseChecklistCompletions")
        let checklistSaved = UserDefaults.standard.integer(forKey: "impulseChecklistSaved")
        let urgesSurvived = UserDefaults.standard.integer(forKey: "urgesSurvivedCount")

        let hasAnyData = checklistCompletions > 0 || checklistSaved > 0 || urgesSurvived > 0

        return Group {
            if hasAnyData {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    sectionHeader(
                        title: "Impulse Control Stats",
                        icon: "brain.head.profile"
                    )

                    HStack(spacing: DS.Spacing.md) {
                        impulseStatCard(
                            value: "\(checklistCompletions)",
                            label: "Checklists",
                            icon: "checklist",
                            color: .noBuyGreen
                        )
                        impulseStatCard(
                            value: "\(checklistSaved)",
                            label: "Resisted",
                            icon: "hand.raised.fill",
                            color: .blue
                        )
                        impulseStatCard(
                            value: "\(urgesSurvived)",
                            label: "Urges Beaten",
                            icon: "brain.fill",
                            color: .purple
                        )
                    }
                }
                .sectionCard()
            }
        }
    }

    private func impulseStatCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .accessibilityHidden(true)

            Text(value)
                .font(.system(.title2, design: .rounded).weight(.black))
                .foregroundStyle(.textPrimary)
                .contentTransition(.numericText())

            Text(label)
                .font(.caption2)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .fill(color.opacity(0.1))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Waiting List Stats (Free + Pro)

    private var waitingListStats: some View {
        let manager = WaitingListManager.shared
        let resistedCount = manager.resistedCount
        let savedMoney = manager.savedMoney
        let activeCount = manager.activeItems.count

        let hasAnyData = resistedCount > 0 || savedMoney > 0 || activeCount > 0

        return Group {
            if hasAnyData {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    sectionHeader(
                        title: "Waiting List",
                        icon: "clock.badge.questionmark"
                    )

                    HStack(spacing: DS.Spacing.md) {
                        impulseStatCard(
                            value: "\(resistedCount)",
                            label: "Resisted",
                            icon: "hand.raised.fill",
                            color: .noBuyGreen
                        )
                        impulseStatCard(
                            value: formattedWaitingSaved(savedMoney),
                            label: "Saved",
                            icon: "turkishlirasign.circle.fill",
                            color: .noBuyGreen
                        )
                        impulseStatCard(
                            value: "\(activeCount)",
                            label: "Waiting",
                            icon: "clock.fill",
                            color: .mandatoryAmber
                        )
                    }
                }
                .sectionCard()
            }
        }
    }

    private func formattedWaitingSaved(_ amount: Double) -> String {
        if amount == 0 { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }

    // MARK: - Pro Teaser

    private var proTeaser: some View {
        VStack(spacing: DS.Spacing.xl) {
            // Blurred preview of charts
            VStack(spacing: DS.Spacing.lg) {
                // Fake stacked bar preview
                HStack(alignment: .bottom, spacing: DS.Spacing.sm) {
                    ForEach(0..<6, id: \.self) { i in
                        VStack(spacing: 1) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.spendRed.opacity(0.35))
                                .frame(width: 28, height: CGFloat([12, 18, 8, 22, 14, 10][i]))
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.noBuyGreen.opacity(0.4))
                                .frame(width: 28, height: CGFloat([40, 65, 50, 80, 55, 70][i]))
                        }
                    }
                }
                .frame(height: 100)

                // Fake line chart preview
                HStack(spacing: 0) {
                    let heights: [CGFloat] = [20, 35, 28, 45, 38, 52, 44, 60]
                    ForEach(Array(heights.enumerated()), id: \.offset) { _, h in
                        VStack {
                            Spacer()
                            Circle()
                                .fill(Color.noBuyGreen.opacity(0.4))
                                .frame(width: 6, height: 6)
                        }
                        .frame(height: h)
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 60)

                // Fake pie chart preview
                HStack(spacing: DS.Spacing.xl) {
                    Circle()
                        .stroke(Color.noBuyGreen.opacity(0.3), lineWidth: 12)
                        .frame(width: 50, height: 50)
                        .overlay {
                            Circle()
                                .trim(from: 0, to: 0.65)
                                .stroke(Color.noBuyGreen.opacity(0.5), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }

                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        fakeLabel(color: .noBuyGreen.opacity(0.5), text: "No-Spend")
                        fakeLabel(color: .mandatoryAmber.opacity(0.5), text: "Essential")
                        fakeLabel(color: .spendRed.opacity(0.5), text: "Discretionary")
                    }
                }
            }
            .padding(DS.Spacing.xl)
            .blur(radius: 6)

            // Overlay CTA
            VStack(spacing: DS.Spacing.md) {
                Image(systemName: "lock.fill")
                    .font(.title)
                    .foregroundStyle(.textSecondary)

                Text("Unlock Detailed Stats")
                    .font(.headline)
                    .foregroundStyle(.textPrimary)

                Text("Monthly trends, streak history, category breakdown, savings analysis, and achievements with Pro.")
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    HapticManager.impact(.medium)
                    showPaywall = true
                } label: {
                    Text("Upgrade to Pro")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.md)
                        .background(Color.noBuyGreen, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Upgrade to Pro")
                .accessibilityHint("Double tap to unlock detailed statistics")
                .accessibilityIdentifier("stats_upgrade_pro")
            }
            .padding(.horizontal, DS.Spacing.xl)
        }
        .padding(.vertical, DS.Spacing.xl)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        .background(Color.surfaceSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Detailed statistics are available with Pro. Tap to upgrade.")
    }

    private func fakeLabel(color: Color, text: String) -> some View {
        HStack(spacing: DS.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption2)
                .foregroundStyle(.textTertiary)
        }
    }

    // MARK: - Shared Components

    private func sectionHeader(title: String, icon: String, showProBadge: Bool = false) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.noBuyGreen)
            Text(title)
                .font(.headline)
                .foregroundStyle(.textPrimary)
            if showProBadge && store.isPro {
                Text(L10n.proFeature)
                    .font(.caption2.bold())
                    .foregroundStyle(.noBuyGreen)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.noBuyGreenLight))
            }
        }
    }

    // MARK: - Empty State

    private var statsEmptyState: some View {
        VStack(spacing: DS.Spacing.lg) {
            Spacer().frame(height: DS.Spacing.xl)

            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 64))
                .foregroundStyle(.noBuyGreen.opacity(0.6))
                .symbolEffect(.pulse, options: reduceMotion ? .nonRepeating : .repeating)
                .accessibilityHidden(true)

            VStack(spacing: DS.Spacing.sm) {
                Text(L10n.emptyStreakTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.textPrimary)

                Text(L10n.emptyStreakDesc)
                    .font(.callout)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
            }

            Spacer().frame(height: DS.Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(DS.Spacing.lg)
        .background(Color.surfaceSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
    }
}

// MARK: - Section Card Modifier

private extension View {
    func sectionCard() -> some View {
        self
            .padding(DS.Spacing.lg)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
            .background(Color.surfaceSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}

// MARK: - Preview

#Preview {
    StatsScreen()
        .environment(StoreService.shared)
        .environment(AchievementManager.shared)
        .modelContainer(for: [DayRecord.self, MandatoryCategory.self], inMemory: true)
}
