import Charts
import SwiftData
import SwiftUI

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
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    private var noBuyRecords: [DayRecord] {
        records.filter(\.isNoBuyDay)
    }

    // MARK: - Computed Chart Data

    private var monthlyBarEntries: [MonthlyBarEntry] {
        viewModel.monthlyData.flatMap { item in [
            MonthlyBarEntry(month: item.label, category: "No-Spend", count: item.noBuyCount),
            MonthlyBarEntry(month: item.label, category: "Spent", count: max(0, item.totalDays - item.noBuyCount)),
        ] }
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
        for weekBack in (0 ..< 12).reversed() {
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
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: DS.Spacing.xxl) {
                        // MARK: - Three claims (Escapement)
                        //
                        // The run against the best · the month so far · EVERY RUN KEPT.
                        // The third is the Doorframe measure (M-09) made visible: an ended run
                        // is drawn as a completed interval, at full dignity, forever. Nothing
                        // zeroes, nothing is cleared — the current run is simply the one with
                        // an open end. It is the churn-risk answer drawn rather than written.
                        theRunClaim
                        monthSoFarClaim
                        everyRunKeptClaim

                        // The analysis layer below is Pro (owner ruling 2026-08-12, which
                        // widened Pro from the round's three rows). The round drew Stats with
                        // NO charts — intervals only — so the charts sit beneath the three
                        // claims rather than replacing them: the brave choice keeps the top of
                        // the screen, and the paid depth is a section, not the subject.
                        if store.isPro {
                            // Savings Estimate (Pro)
                            savingsEstimateCard
                                .offset(y: appeared ? 0 : 20)
                                .opacity(appeared ? 1 : 0)
                                .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 4), value: appeared)

                            // Monthly Trend — stacked bar (Pro)
                            monthlyTrendChart
                                .id("pro-charts")
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
                .background(Color.surfaceField)
                .navigationTitle("Statistics")
                .navigationBarTitleDisplayMode(.large)
                .onAppear {
                    #if DEBUG
                        // Store-shots tour: jump to the Pro charts without animation.
                        if ScreenshotTour.state == .statsCharts {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withTransaction(\.disablesAnimations, true) {
                                    proxy.scrollTo("pro-charts", anchor: .top)
                                }
                            }
                        }
                    #endif
                }
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(store: store, entry: .analysis)
        }
        .onAppear {
            refreshStats()
            #if DEBUG
                // Store-shots tour: no skeleton, no entrance animation — the
                // capture must be deterministic regardless of settle time.
                if DemoMode.isActive {
                    isLoading = false
                    appeared = true
                    return
                }
            #endif
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
                GridItem(.flexible(), spacing: DS.Spacing.md),
            ], spacing: DS.Spacing.md) {
                statCard(
                    title: "Total Days",
                    value: "\(viewModel.totalNoBuyDays)",
                    icon: "checkmark.circle.fill",
                    color: .accentKept
                )
                .accessibilityLabel("Total no-spend days: \(viewModel.totalNoBuyDays)")
                .offset(y: appeared ? 0 : 20)
                .opacity(appeared ? 1 : 0)
                .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 0), value: appeared)

                statCard(
                    title: "Estimated Savings",
                    value: formattedSavings,
                    icon: "banknote.fill",
                    color: .accentKept
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
                    color: .accentSpentMark
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
                    color: .accentSpentMark
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
                    color: .accentSpentText
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
                    .foregroundStyle(.inkSecondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.xs) {
                Text(value)
                    .font(.title.bold())
                    .foregroundStyle(.inkPrimary)
                    .contentTransition(.numericText())
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.inkSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.lg)
        .background(DS.Gradient.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .background(Color.surfaceWell, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .background(Color.surfaceDial, in: RoundedRectangle(cornerRadius: DS.Radius.md))

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
                        .font(Font.adaptiveDisplay(size: 48, weight: .semibold, isRegular: isRegular))
                        .foregroundStyle(.accentKept)
                        .contentTransition(.numericText())
                        .animation(reduceMotion ? nil : DS.Anim.normal, value: viewModel.estimatedSavings)

                    Text("\(viewModel.totalNoBuyDays) no-spend days × \(formattedDailyEstimate)/day")
                        .font(.subheadline)
                        .foregroundStyle(.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.md)
            } else {
                VStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundStyle(.inkSecondary)
                    Text("Set your daily spending estimate in Settings to see savings")
                        .font(.subheadline)
                        .foregroundStyle(.inkSecondary)
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
                "No-Spend": Color.accentKept,
                "Spent": Color.accentSpentText,
            ])
            .chartLegend(position: .bottom, alignment: .center, spacing: DS.Spacing.md)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(Color.inkSecondary.opacity(0.3))
                    AxisValueLabel()
                        .foregroundStyle(Color.inkSecondary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.inkSecondary)
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
                            .foregroundStyle(.inkSecondary)
                    }
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.inkSecondary)
                }
            }
            .frame(height: 210)
        }
        .sectionCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Weekly distribution chart showing which days of the week have the most no-spend days")
    }

    private func barColor(for item: WeekdayData) -> Color {
        if item.percentage >= 70 { return .accentKept }
        if item.percentage >= 40 { return .stateWait }
        return .accentSpentText
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
                    .foregroundStyle(.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DS.Spacing.xl)
            } else {
                Chart(weeklyStreakPoints) { point in
                    AreaMark(
                        x: .value("Week", point.weekLabel),
                        y: .value("Streak", point.streakLength)
                    )
                    .foregroundStyle(
                        Color.accentKept.opacity(0.3)
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Week", point.weekLabel),
                        y: .value("Streak", point.streakLength)
                    )
                    .foregroundStyle(Color.accentKept)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Week", point.weekLabel),
                        y: .value("Streak", point.streakLength)
                    )
                    .foregroundStyle(Color.accentKept)
                    .symbolSize(36)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(Color.inkSecondary.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(Color.inkSecondary)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.inkSecondary)
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
                    .foregroundStyle(.inkSecondary)
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
                        "No-Spend": Color.accentKept,
                        "Essential": Color.stateWait,
                        "Discretionary": Color.accentSpentText,
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
                                        .foregroundStyle(.inkPrimary)
                                    Text("\(slice.count) days")
                                        .font(.caption2)
                                        .foregroundStyle(.inkSecondary)
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
        case "No-Spend": .accentKept
        case "Essential": .stateWait
        case "Discretionary": .accentSpentText
        default: .inkSecondary
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
                    .foregroundStyle(.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DS.Spacing.xl)
            } else {
                Chart(noBuyRatePoints) { point in
                    AreaMark(
                        x: .value("Month", point.label),
                        y: .value("Rate", point.rate)
                    )
                    .foregroundStyle(
                        Color.accentKept.opacity(0.4)
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Month", point.label),
                        y: .value("Rate", point.rate)
                    )
                    .foregroundStyle(Color.accentKept.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Month", point.label),
                        y: .value("Rate", point.rate)
                    )
                    .foregroundStyle(Color.accentKept)
                    .symbolSize(30)
                    .annotation(position: .top, spacing: 4) {
                        if point.rate > 0 {
                            Text(String(format: "%.0f%%", point.rate))
                                .font(.caption2.bold())
                                .foregroundStyle(.inkSecondary)
                        }
                    }
                }
                .chartYScale(domain: 0 ... 100)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(Color.inkSecondary.opacity(0.3))
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text("\(v)%")
                                    .font(.caption2)
                                    .foregroundStyle(Color.inkSecondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.inkSecondary)
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
                                .foregroundStyle(trend.isImproving ? Color.accentKept : Color.accentSpentText)
                                .symbolEffect(.bounce, value: trend.delta)

                            Text(String(format: "%+.0f%%", trend.delta))
                                .font(.caption.bold())
                                .foregroundStyle(trend.isImproving ? Color.accentKept : Color.accentSpentText)
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
                .foregroundStyle(.inkSecondary)

            Text(String(format: "%.0f%%", percentage))
                .font(.title2.bold())
                .foregroundStyle(isPrimary ? Color.inkPrimary : Color.inkSecondary)

            Text(detail)
                .font(.caption2)
                .foregroundStyle(.inkSecondary)
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
                    .foregroundStyle(.inkSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, DS.Spacing.xl)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    heatmapGrid
                }
            }

            HStack(spacing: DS.Spacing.lg) {
                heatmapLegendItem(color: Color.accentKept, label: "No-Spend")
                heatmapLegendItem(color: Color.accentSpentText, label: "Spent")
                heatmapLegendItem(color: Color.surfaceWell, label: "Unrecorded")
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
                case .noBuy: .accentKept
                case .spent: .accentSpentText
                case .unrecorded: .surfaceWell
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
                .foregroundStyle(.inkSecondary)
        }
    }

    // MARK: - Claim 1 — the run

    private var runs: [StreakCalculator.Run] {
        StreakCalculator.allRuns(from: records)
    }

    private var openRun: StreakCalculator.Run? { runs.first(where: \.isOpen) }
    private var bestRun: StreakCalculator.Run? { runs.max(by: { $0.days < $1.days }) }

    private var theRunClaim: some View {
        claimCard(title: "The run") {
            if records.isEmpty {
                // The shape of the answer before any data (deliverable 9): the slot holds, with
                // one factual line. No tutorial, no zero dressed up as a score.
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("0")
                        .font(.system(size: 44, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(.inkPrimary)
                    Text("Begins tonight")
                        .font(.subheadline)
                        .foregroundStyle(.inkPrimary)
                    Text("The first answer starts the first run. A best appears when a run ends.")
                        .font(.footnote)
                        .foregroundStyle(.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                HStack(alignment: .center, spacing: DS.Spacing.xl) {
                    DialFace(
                        size: 118,
                        scale: .interval,
                        progress: runFraction,
                        handPosition: nil
                    ) {
                        VStack(spacing: 0) {
                            Text("\(openRun?.days ?? 0)")
                                .font(.system(size: 34, weight: .semibold))
                                .monospacedDigit()
                                .foregroundStyle(.inkPrimary)
                            Text("of the best")
                                .font(.system(size: 9))
                                .foregroundStyle(.inkSecondary)
                                .fixedSize()
                        }
                    }

                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text(openRun.map { "\($0.days) days, open" } ?? "No run open")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.inkPrimary)

                        if let best = bestRun {
                            Text("Best — \(best.days) · \(Self.range(best))")
                                .font(.footnote)
                                .foregroundStyle(.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let gap = gapToBest {
                            Text(gap)
                                .font(.footnote)
                                .foregroundStyle(.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    /// The open run drawn against the best — the arc is a comparison, not a percentage.
    private var runFraction: Double {
        guard let open = openRun, let best = bestRun, best.days > 0 else { return 0 }
        return min(Double(open.days) / Double(best.days), 1)
    }

    private var gapToBest: String? {
        guard let open = openRun, let best = bestRun else { return nil }
        if open.days >= best.days { return "This is the longest run on record." }
        return "\(best.days - open.days) more would match it"
    }

    // MARK: - Claim 2 — the month so far

    private var monthSoFarClaim: some View {
        claimCard(title: Self.monthName.string(from: .now) + " so far") {
            if records.isEmpty {
                Text("today, open — the strip grows one tick a night")
                    .font(.footnote)
                    .foregroundStyle(.inkSecondary)
            } else {
                Text(monthLine)
                    .font(.subheadline)
                    .foregroundStyle(.inkPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var monthLine: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let monthDays = records.filter { calendar.isDate($0.date, equalTo: today, toGranularity: .month) }
        let answered = monthDays.count
        let kept = monthDays.filter(\.isNoBuyDay).count
        let todayAnswered = monthDays.contains { calendar.isDateInToday($0.date) }
        return "\(answered) answered · \(kept) kept" + (todayAnswered ? "" : " · today open")
    }

    // MARK: - Claim 3 — every run, kept

    private var everyRunKeptClaim: some View {
        claimCard(title: "Every run, kept") {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                if runs.isEmpty {
                    Text("day 0 — the first interval opens with tonight's answer")
                        .font(.footnote)
                        .foregroundStyle(.inkSecondary)
                } else {
                    if let since = runs.last {
                        Text("since \(Self.longDate.string(from: since.start))")
                            .font(.caption)
                            .foregroundStyle(.inkSecondary)
                    }

                    ForEach(runs.prefix(6)) { run in
                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            HStack {
                                Text("\(run.days)")
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(.inkPrimary)
                                Text(run.isOpen ? "since \(Self.longDate.string(from: run.start)) · open"
                                    : "\(Self.range(run)) · settled")
                                    .font(.caption)
                                    .foregroundStyle(.inkSecondary)
                            }
                            IntervalBar(
                                days: run.days,
                                best: bestRun?.days ?? run.days,
                                isOpen: run.isOpen,
                                isDense: runs.count > 8
                            )
                        }
                        .accessibilityElement(children: .combine)
                    }

                    if runs.count > 6 {
                        Text("\(runs.count - 6) earlier runs")
                            .font(.caption)
                            .foregroundStyle(.inkSecondary)
                    }
                }

                Text("Ended runs stay. Nothing here is ever zeroed or cleared.")
                    .font(.caption)
                    .foregroundStyle(.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Claim shell

    private func claimCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text(title)
                .font(.caption)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(.inkSecondary)
                .accessibilityAddTraits(.isHeader)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.sheet)
                .fill(Color.surfaceDial)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.sheet)
                        .strokeBorder(Color.inkHairline, lineWidth: DS.Stroke.hairline)
                )
        )
    }

    private static func range(_ run: StreakCalculator.Run) -> String {
        "\(shortDate.string(from: run.start)) to \(shortDate.string(from: run.end))"
    }

    private static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "d MMM"
        return f
    }()

    private static let longDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "d MMMM"
        return f
    }()

    private static let monthName: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMMM"
        return f
    }()

    // MARK: - Achievements Grid

    private var achievementsGrid: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            // v2.0.0: achievements are earned, not bought. Locking a badge the user already
            // worked for behind a subscription made the reward feel like bait — the free tier
            // now carries all of them, and Pro sells depth (analysis, export, challenges).
            sectionHeader(
                title: "Achievements",
                icon: "medal.fill",
                showProBadge: false
            )

            let allAchievements = achievementManager.achievements
            let unlockedCount = allAchievements.filter(\.isUnlocked).count
            let totalCount = allAchievements.count

            Text("\(unlockedCount)/\(totalCount) achievements unlocked")
                .font(.caption)
                .foregroundStyle(.inkSecondary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: DS.Spacing.md),
                GridItem(.flexible(), spacing: DS.Spacing.md),
                GridItem(.flexible(), spacing: DS.Spacing.md),
            ], spacing: DS.Spacing.md) {
                ForEach(allAchievements) { achievement in
                    achievementCell(achievement)
                }
            }
        }
        .sectionCard()
    }

    private func achievementCell(_ achievement: Achievement) -> some View {
        VStack(spacing: DS.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked
                        ? Color.accentKept.opacity(0.15)
                        : Color.surfaceWell)
                    .frame(width: 52, height: 52)

                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundStyle(achievement.isUnlocked ? Color.accentKept : Color.inkSecondary)
            }

            Text(achievement.title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(achievement.isUnlocked ? Color.inkPrimary : Color.inkSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, DS.Spacing.sm)
        .padding(.horizontal, DS.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.sm)
                .fill(achievement.isUnlocked ? Color.surfaceDial : .clear)
        )

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
                            color: .accentKept
                        )
                        impulseStatCard(
                            value: "\(checklistSaved)",
                            label: "Resisted",
                            icon: "hand.raised.fill",
                            color: .stateWait
                        )
                        impulseStatCard(
                            value: "\(urgesSurvived)",
                            label: "Urges Beaten",
                            icon: "brain.fill",
                            color: .stateWait
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
                .font(.title2.weight(.semibold))
                .foregroundStyle(.inkPrimary)
                .contentTransition(.numericText())

            Text(label)
                .font(.caption2)
                .foregroundStyle(.inkSecondary)
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
                            color: .accentKept
                        )
                        impulseStatCard(
                            value: formattedWaitingSaved(savedMoney),
                            label: "Saved",
                            icon: "banknote.fill",
                            color: .accentKept
                        )
                        impulseStatCard(
                            value: "\(activeCount)",
                            label: "Waiting",
                            icon: "clock.fill",
                            color: .stateWait
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

    // MARK: - What Pro reads
    //
    // Named in words, not shown as a blurred sample. The v1 version drew fabricated bars and a
    // fabricated line, blurred them, and put a padlock on top — a picture of data the person does
    // not have, which the accepted design bans outright and which is the App Store's own
    // definition of a misleading screen. It also sold "achievements", which are free in v2.0.0.
    //
    // The honest form is the one the paywall already uses: say what the analysis is, on the same
    // claim-card surface as everything else, and let the person decide.
    private var proTeaser: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("The analysis layer")
                .font(.headline)
                .foregroundStyle(.inkPrimary)

            Text("Pro reads your own record back to you: monthly trend, weekday pattern, streak history, category split, no-spend rate and savings estimate.")
                .font(.subheadline)
                .foregroundStyle(.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                HapticManager.impact(.medium)
                showPaywall = true
            } label: {
                Text("See NoBuy Pro")
                    .font(.headline)
                    .foregroundStyle(Color.inkOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Capsule().fill(Color.accentKept))
            }
            .buttonStyle(.scale)
            .accessibilityIdentifier("stats_upgrade_pro")
        }
        .padding(DS.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .fill(Color.surfaceWell)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.md)
                        .strokeBorder(Color.inkHairline, lineWidth: DS.Stroke.hairline)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("The analysis layer. Pro reads your own record back to you: monthly trend, weekday pattern, streak history, category split, no-spend rate and savings estimate.")
    }

    private func sectionHeader(title: String, icon: String, showProBadge: Bool = false) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.accentKept)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
                .foregroundStyle(.inkPrimary)
            if showProBadge, store.isPro {
                Text(L10n.proFeature)
                    .font(.caption2.bold())
                    .foregroundStyle(.accentKept)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.accentKeptWash))
            }
        }
    }

    // MARK: - Empty State

    private var statsEmptyState: some View {
        VStack(spacing: DS.Spacing.lg) {
            Spacer().frame(height: DS.Spacing.xl)

            Image(systemName: "chart.bar.doc.horizontal")
                .font(Font.adaptiveDisplay(size: 64, isRegular: isRegular))
                .foregroundStyle(.accentKept.opacity(0.6))
                .symbolEffect(.pulse, options: reduceMotion ? .nonRepeating : .repeating)
                .accessibilityHidden(true)

            VStack(spacing: DS.Spacing.sm) {
                Text(L10n.emptyStreakTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.inkPrimary)

                Text(L10n.emptyStreakDesc)
                    .font(.callout)
                    .foregroundStyle(.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
            }

            Spacer().frame(height: DS.Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(DS.Spacing.lg)
        .background(DS.Gradient.card, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        .background(Color.surfaceDial, in: RoundedRectangle(cornerRadius: DS.Radius.lg))

    }
}

// MARK: - Section Card Modifier

private extension View {
    func sectionCard() -> some View {
        self
            .padding(DS.Spacing.lg)
            .background(DS.Gradient.card, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
            .background(Color.surfaceWell, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
            .background(Color.surfaceDial, in: RoundedRectangle(cornerRadius: DS.Radius.lg))

    }
}

// MARK: - Preview

#Preview {
    StatsScreen()
        .environment(StoreService.shared)
        .environment(AchievementManager.shared)
        .modelContainer(for: [DayRecord.self, MandatoryCategory.self], inMemory: true)
}
