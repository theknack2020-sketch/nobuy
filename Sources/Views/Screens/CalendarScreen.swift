import SwiftData
import SwiftUI

// MARK: - Calendar — the timing sheet (Escapement, v2.0.0)
//
// Round-2 correction 1, answered by the design and implemented here: **the ring is gone from
// this room.** The eye compares rows, not arcs, so the month is a week-row grid in the same
// silvered material — day cells on the dial surface, the five truths in the same tick
// vocabulary, and a kept-rate rail at the end of every row so the shape of the month (which
// weeks held, where spending clusters) reads in one pass.
//
// The sweep survives here only as the small month-progress bezel in the header. Rings stay
// where a single interval is the subject: Today, the urge timer, the circular widget.
//
// Pre-record days carry a bare numeral on the field — no cell, no judgement. "Nothing here is
// missing; it was simply never asked."

struct CalendarScreen: View {
    @Query(sort: \DayRecord.date, order: .reverse) private var records: [DayRecord]
    @Environment(StoreService.self) private var store
    @State private var viewModel = CalendarViewModel()
    @State private var selectedDateForEdit: IdentifiableDate?
    @State private var showRatingCard = false
    @State private var showPaywall = false
    @State private var isLoading = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool { sizeClass == .regular }

    /// The first day the record holds anything. Days before it get a bare numeral.
    private var firstRecordedDay: Date? {
        records.map(\.date).min().map { Calendar.current.startOfDay(for: $0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.xl) {
                    monthHeader

                    if isBeforeTheRecord {
                        beforeTheRecordNotice
                    } else {
                        weekGrid
                        legend
                    }
                }
                .padding(.horizontal, DS.Spacing.screenGutter)
                .padding(.top, DS.Spacing.md)
                .padding(.bottom, DS.Spacing.xxl)
                .redacted(reason: isLoading ? .placeholder : [])
                .allowsHitTesting(!isLoading)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.surfaceField)
            .navigationTitle(L10n.calendarTitle)
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedDateForEdit, onDismiss: {
                if RatingPrompt.shared.pendingPrePrompt { showRatingCard = true }
            }) { item in
                let calendar = Calendar.current
                let normalized = calendar.startOfDay(for: item.date)
                let existing = records.first { calendar.startOfDay(for: $0.date) == normalized }
                DayEditSheet(date: item.date, existingRecord: existing)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showRatingCard, onDismiss: {
                RatingPrompt.shared.dismissed()
            }) {
                RatingPromptCard(streak: RatingPrompt.shared.milestoneStreak)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView(
                    store: store,
                    entry: .recordWindow(held: records.count, window: StoreService.freeRecordWindowDays)
                )
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

    // MARK: - Header
    //
    // The month, the two steps, the small month-progress bezel, and the month's kept count.
    // The bezel is the ONLY ring left in this room, and it has a job: how far through the
    // month we are.

    private var monthHeader: some View {
        HStack(spacing: DS.Spacing.sm) {
            Text(viewModel.monthTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(.inkPrimary)
                .accessibilityAddTraits(.isHeader)

            stepButton(systemName: "chevron.left", label: "Previous month") { goBack() }

            stepButton(systemName: "chevron.right", label: "Next month") {
                guard viewModel.canGoForward else { return }
                HapticManager.impact(.light)
                withAnimation(reduceMotion ? nil : DS.Anim.functional) {
                    viewModel.goToNextMonth()
                }
            }
            .opacity(viewModel.canGoForward ? 1 : 0.35)
            .disabled(!viewModel.canGoForward)

            Spacer(minLength: DS.Spacing.xs)

            HStack(spacing: DS.Spacing.sm) {
                DialFace(size: 24, scale: .interval, progress: monthProgress, handPosition: nil) {
                    EmptyView()
                }

                Text("\(monthKeptCount) kept")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.inkSecondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(monthKeptCount) days kept this month")
        }
    }

    private func stepButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.inkPrimary)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.scale)
        .accessibilityLabel(label)
    }

    /// Stepping back past the free window is the one place this screen sells anything — and it
    /// names the limit in the user's own numbers rather than refusing silently.
    private func goBack() {
        let calendar = Calendar.current
        guard let target = calendar.date(byAdding: .month, value: -1, to: viewModel.currentMonth),
              let dayCount = calendar.range(of: .day, in: .month, for: target)?.count,
              let lastDay = calendar.date(bySetting: .day, value: dayCount, of: target)
        else { return }

        guard store.canOpenRecord(on: lastDay) else {
            HapticManager.tap()
            showPaywall = true
            return
        }

        HapticManager.impact(.light)
        withAnimation(reduceMotion ? nil : DS.Anim.functional) {
            viewModel.goToPreviousMonth()
        }
    }

    // MARK: - The grid

    private var weekGrid: some View {
        VStack(spacing: DS.Spacing.cellGap) {
            weekdayHeader

            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: DS.Spacing.cellGap) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        cell(for: day)
                    }

                    // The kept-rate rail: how many of this week's days held. This is what makes
                    // the month's SHAPE readable in one pass — the job the dial calendar could
                    // not do, and the reason the ring left this room.
                    Text(keptCount(in: week).map(String.init) ?? "")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.inkSecondary)
                        .frame(width: 24)
                        .accessibilityLabel(keptCount(in: week).map { "\($0) kept this week" } ?? "")
                }
            }
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: DS.Spacing.cellGap) {
            ForEach(Array(viewModel.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption2.weight(.medium))
                    .textCase(.uppercase)
                    .foregroundStyle(.inkSecondary)
                    .frame(maxWidth: .infinity)
            }
            Text("K")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.inkSecondary)
                .frame(width: 24)
                .accessibilityLabel("Days kept, per week")
        }
    }

    @ViewBuilder
    private func cell(for day: Date?) -> some View {
        if let day {
            let calendar = Calendar.current
            let status = viewModel.dayStatus(for: day, records: records)
            let dayNumber = calendar.component(.day, from: day)
            let isToday = calendar.isDateInToday(day)

            if let truth = status.truth, !isPreRecord(day) {
                Button {
                    HapticManager.tap()
                    selectedDateForEdit = IdentifiableDate(date: day)
                } label: {
                    DayCell(
                        day: dayNumber,
                        truth: truth,
                        isToday: isToday,
                        hasNote: hasNote(on: day)
                    )
                }
                .buttonStyle(.plain)
            } else {
                // Pre-record and future days: a bare numeral on the field. No cell, no mark, no
                // judgement — the app was not asking yet, or has not asked yet.
                Text("\(dayNumber)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.stateNotYet)
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .accessibilityLabel("\(dayNumber), \(isPreRecord(day) ? "before your record starts" : "not yet")")
            }
        } else {
            Color.clear.frame(maxWidth: .infinity, minHeight: 46)
        }
    }

    private var legend: some View {
        HStack(spacing: DS.Spacing.md) {
            ForEach(DayTruth.allCases, id: \.self) { truth in
                HStack(spacing: DS.Spacing.xs) {
                    DayMark(truth: truth)
                        .scaleEffect(0.8)
                    Text(legendLabel(truth))
                        .font(.caption2)
                        .foregroundStyle(.inkSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, DS.Spacing.sm)
        .accessibilityHidden(true)
    }

    private func legendLabel(_ truth: DayTruth) -> String {
        switch truth {
        case .kept: "no-spend"
        case .spent: "spent"
        case .mandatoryOnly: "essentials"
        case .frozen: "frozen"
        case .notYet: "not yet"
        }
    }

    // MARK: - Before the record

    private var isBeforeTheRecord: Bool {
        guard let first = firstRecordedDay else { return false }
        let calendar = Calendar.current
        guard let dayCount = calendar.range(of: .day, in: .month, for: viewModel.currentMonth)?.count,
              let monthEnd = calendar.date(bySetting: .day, value: dayCount, of: viewModel.currentMonth)
        else { return false }
        return calendar.startOfDay(for: monthEnd) < first
    }

    private var beforeTheRecordNotice: some View {
        VStack(spacing: DS.Spacing.sm) {
            Text("Before the record.")
                .font(.headline)
                .foregroundStyle(.inkPrimary)

            if let first = firstRecordedDay {
                Text("NoBuy began keeping days on \(Self.longDate.string(from: first)).")
                    .font(.subheadline)
                    .foregroundStyle(.inkSecondary)
            }

            Text("Nothing here is missing — it was simply never asked.")
                .font(.subheadline)
                .foregroundStyle(.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.xxxl)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Derivations

    /// The month laid out as week rows, with leading and trailing blanks.
    private var weeks: [[Date?]] {
        let days = viewModel.daysInMonth
        var cells: [Date?] = Array(repeating: nil, count: viewModel.firstDayOffset)
        cells.append(contentsOf: days.map { Optional($0) })
        while cells.count % 7 != 0 { cells.append(nil) }
        return stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0 ..< $0 + 7]) }
    }

    /// Nil when a week holds no answered day at all — an empty rail rather than a "0", which
    /// would read as a week that failed instead of a week that was never asked about.
    private func keptCount(in week: [Date?]) -> Int? {
        let answered = week.compactMap { $0 }.filter { day in
            guard !isPreRecord(day) else { return false }
            let status = viewModel.dayStatus(for: day, records: records)
            return status != .future && status != .unrecorded
        }
        guard !answered.isEmpty else { return nil }
        return answered.filter { day in
            switch viewModel.dayStatus(for: day, records: records) {
            case .noBuy, .frozen, .essential: true
            default: false
            }
        }.count
    }

    private var monthKeptCount: Int {
        weeks.compactMap { keptCount(in: $0) }.reduce(0, +)
    }

    /// How far through the month we are — the header bezel's one job.
    private var monthProgress: Double {
        let calendar = Calendar.current
        let now = Date.now
        guard calendar.isDate(viewModel.currentMonth, equalTo: now, toGranularity: .month),
              let range = calendar.range(of: .day, in: .month, for: now)
        else {
            return calendar.compare(viewModel.currentMonth, to: now, toGranularity: .month) == .orderedAscending ? 1 : 0
        }
        return Double(calendar.component(.day, from: now)) / Double(range.count)
    }

    private func isPreRecord(_ day: Date) -> Bool {
        guard let first = firstRecordedDay else { return true }
        return Calendar.current.startOfDay(for: day) < first
    }

    private func hasNote(on day: Date) -> Bool {
        let calendar = Calendar.current
        let normalized = calendar.startOfDay(for: day)
        return records.first { calendar.startOfDay(for: $0.date) == normalized }
            .map { !($0.note ?? "").isEmpty } ?? false
    }

    private static let longDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "d MMMM yyyy"
        return f
    }()
}

// MARK: - Sheet identity

struct IdentifiableDate: Identifiable {
    let date: Date
    var id: TimeInterval {
        date.timeIntervalSince1970
    }
}
