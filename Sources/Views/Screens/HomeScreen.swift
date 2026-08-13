import SwiftData
import SwiftUI
import WidgetKit

struct HomeScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreService.self) private var store
    @Environment(QuickActionHandler.self) private var quickActionHandler
    @Query(sort: \DayRecord.date, order: .reverse) private var records: [DayRecord]
    @State private var viewModel = HomeViewModel()
    @State private var showPaywall = false
    @State private var paywallEntry: PaywallEntry = .general
    @State private var showShareSheet = false
    @State private var showMilestoneModal = false
    @State private var showConfetti = false
    @State private var showRatingCard = false
    @State private var shareCardImage: UIImage?
    @State private var showShareCardSheet = false
    @State private var summaryAppeared = false
    @State private var showChallengeSetup = false
    @State private var celebrationAchievement: Achievement?
    @State private var showErrorBanner = false
    @State private var isLoading = true
    @State private var sectionsAppeared = false


    private static let celebrationStreaks: Set<Int> = [1, 3, 7, 14, 30, 60, 100]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.scenePhase) private var scenePhase

    private var isRegular: Bool {
        sizeClass == .regular
    }

    @State private var showMilestoneBanner = false
    @State private var milestoneDay = 0
    @State private var showImpulseChecklist = false
    @State private var showUrgeSurfing = false
    @State private var showChallengeCelebration = false
    @State private var showWaitingList = false
    @State private var showResetConfirmation = false

    /// countXL (78pt) and the question (20pt) are the two type roles the tokens size in points.
    /// Both scale with the user's setting; the count floors at 56 and the question at 20, below
    /// which they stop doing the job they were sized for.
    @ScaledMetric(relativeTo: .largeTitle) private var scaledCount: CGFloat = 78
    @ScaledMetric(relativeTo: .body) private var scaledQuestion: CGFloat = 20

    /// Milestones that trigger a soft paywall nudge
    private let milestoneDays: Set<Int> = [7, 14, 30, 60, 100]

    private var softPaywallBinding: Binding<Bool> {
        Binding(
            get: { SoftPaywallTracker.shared.shouldShowPaywall && !store.isPro },
            set: { _ in SoftPaywallTracker.shared.resetShown() }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceField
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                // The whole screen ticks once a minute: the arc, the hand and the remainder all
                // read from the same clock, and a dial that lags its own remainder is worse
                // than no dial. One TimelineView drives them so they can never disagree.
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    ScrollView {
                        VStack(spacing: 0) {
                            dateHeader
                                .padding(.top, DS.Spacing.sm)

                            dayDial(now: context.date)
                                .padding(.top, DS.Spacing.lg)

                            // Fixed slot: the remainder normally, the fault notice when a past
                            // day is unanswered. It always renders — an element that appears and
                            // disappears reads as disorder (M-05).
                            noticeLine(now: context.date)
                                .padding(.top, DS.Spacing.lg)

                            questionSheet
                                .padding(.top, DS.Spacing.xl)

                            well
                                .padding(.top, DS.Spacing.xxl)

                            // Everything below is v1 furniture that has not yet moved to its
                            // v2 home in Stats. It is kept mounted rather than deleted so no
                            // feature silently disappears mid-redesign; each one leaves as its
                            // destination screen is rebuilt.
                            legacySections
                                .padding(.top, DS.Spacing.xxl)
                        }
                        .padding(.horizontal, DS.Spacing.screenGutter)
                        .padding(.bottom, DS.Spacing.xxl)
                    }
                }
                .redacted(reason: isLoading ? .placeholder : [])
                .allowsHitTesting(!isLoading)
                .scrollDismissesKeyboard(.interactively)

                if showMilestoneModal {
                    MilestoneModal(streak: viewModel.streakInfo.currentStreak, achievement: celebrationAchievement) {
                        showMilestoneModal = false
                        AchievementManager.shared.clearNewlyUnlocked()
                        celebrationAchievement = nil
                        // Celebration first, honest review ask second.
                        if RatingPrompt.shared.pendingPrePrompt {
                            showRatingCard = true
                        }
                    }
                    .transition(.opacity)
                    .zIndex(10)
                }

                if showConfetti {
                    ConfettiView()
                        .zIndex(11)
                }

                if showChallengeCelebration {
                    ChallengeCelebrationModal(
                        totalDays: viewModel.challengeDuration
                    ) {
                        withAnimation(DS.Anim.quick) {
                            showChallengeCelebration = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(10)
                }
            }
            .navigationTitle(L10n.appTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        Button {
                            showUrgeSurfing = true
                        } label: {
                            Image(systemName: "brain.head.profile")
                                .foregroundStyle(.accentKept)
                        }
                        .buttonStyle(.scale)
                        .accessibilityLabel("Urge Surfing")
                        .accessibilityHint("Double tap to open urge surfing mindfulness timer")
                        .accessibilityIdentifier("toolbar_urge_surfing")

                        Button {
                            showWaitingList = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "clock.badge.questionmark")
                                    .foregroundStyle(.accentKept)

                                if WaitingListManager.shared.activeItems.count > 0 {
                                    Text("\(WaitingListManager.shared.activeItems.count)")
                                        .font(Font.adaptiveBadge(isRegular: isRegular))
                                        .foregroundStyle(Color.inkOnAccent)
                                        .frame(width: 16, height: 16)
                                        .background(Circle().fill(Color.accentSpentText))
                                        .offset(x: 6, y: -6)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .buttonStyle(.scale)
                        .accessibilityLabel("Waiting List, \(WaitingListManager.shared.activeItems.count) items")
                        .accessibilityHint("Double tap to open your waiting list")
                        .accessibilityIdentifier("toolbar_waiting_list")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // Pro badge teaser
                        if !store.isPro {
                            Button {
                                showPaywall = true
                            } label: {
                                Text(L10n.proBadge)
                                    .font(.caption2.bold())
                                    .foregroundStyle(.accentKept)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.accentKeptWash))
                            }
                            .buttonStyle(.scale)
                            .accessibilityLabel("Upgrade to Pro")
                            .accessibilityHint("Double tap to view Pro features")
                            .accessibilityIdentifier("toolbar_pro_badge")
                        }

                        // Share button — text share for free, rendered card for Pro
                        if viewModel.streakInfo.currentStreak > 0 {
                            if store.isPro {
                                Button {
                                    shareEnhancedCard()
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundStyle(.accentKept)
                                }
                                .buttonStyle(.scale)
                                .accessibilityLabel("Share enhanced streak card")
                                .accessibilityHint("Double tap to share your streak card image")
                            } else {
                                ShareLink(
                                    item: "\(viewModel.streakInfo.currentStreak) days without an unnecessary purchase.",
                                    subject: Text("My NoBuy Streak"),
                                    message: Text("I'm on a \(viewModel.streakInfo.currentStreak)-day no-spend streak!")
                                ) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundStyle(.accentKept)
                                }
                                .accessibilityLabel("Share your streak")
                                .accessibilityHint("Double tap to share your no-spend streak")
                            }
                        }
                    }
                }
            }

            // MARK: - Confirmation Dialogs

            .confirmationDialog(
                "Reset today's record?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset to No Record", role: .destructive) {
                    resetTodayRecord()
                }
                Button(L10n.cancel, role: .cancel) {}
            } message: {
                Text("This will remove today's entry. You can re-log it afterwards.")
            }
        }
        .onAppear {
            #if DEBUG
                // Store-shots tour: present the requested tool sheet without
                // animation so the capture never catches a mid-slide frame.
                // Slight delay: presenting the instant onAppear fires is flaky
                // on iPad's split-view cold start (sheet silently no-ops).
                // Reads the ONE vocabulary (`ScreenshotTour.sheet`) rather than matching raw
                // cases here — the v2 keys were added to the enum and this switch would have
                // kept ignoring them, which is how a panel set silently captures the wrong screen.
                if let requested = ScreenshotTour.sheet {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withTransaction(\.disablesAnimations, true) {
                            switch requested {
                            case .urgeSurfing: showUrgeSurfing = true
                            case .checklist: showImpulseChecklist = true
                            }
                        }
                    }
                }
            #endif
            viewModel.resetMonthlyFreezeIfNeeded(isPro: store.isPro)
            viewModel.loadToday(records: records)
            checkMilestone()
            checkChallengeCelebration()
            if viewModel.lastError != nil {
                withAnimation { showErrorBanner = true }
            }
            consumePendingMarkNoBuy()
            if isLoading {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation { isLoading = false }
                }
            }
            if !sectionsAppeared {
                sectionsAppeared = true
            }
        }
        .onChange(of: records.count) {
            viewModel.loadToday(records: records)
            checkChallengeCelebration()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Warm resume (possibly across midnight): onAppear does not re-fire,
            // so refresh today's record and streak when we become active.
            if newPhase == .active {
                viewModel.loadToday(records: records)
            }
        }
        .onChange(of: store.isPro) { _, isPro in
            // Mid-month upgrade: grant unlimited freezes the moment Pro lands.
            if isPro {
                viewModel.resetMonthlyFreezeIfNeeded(isPro: true)
            }
        }
        .onReceive(
            NotificationCenter.default
                .publisher(for: .NSCalendarDayChanged)
                .receive(on: DispatchQueue.main)
        ) { _ in
            // App left foregrounded across local midnight: refresh so the
            // streak and today-status flip without a scene transition.
            viewModel.loadToday(records: records)
        }
        .onChange(of: quickActionHandler.pendingMarkNoBuy) { _, pending in
            if pending {
                consumePendingMarkNoBuy()
            }
        }
        .onChange(of: viewModel.streakInfo.currentStreak) { _, newStreak in
            checkMilestoneForStreak(newStreak)
        }
        .onChange(of: viewModel.lastError) { _, newError in
            withAnimation {
                showErrorBanner = newError != nil
            }
        }
        .sheet(isPresented: $viewModel.showSpendOptions) {
            SpendOptionsSheet(viewModel: viewModel, records: records)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showStreakBreak) {
            StreakBreakView(
                previousStreak: viewModel.previousStreakBeforeBreak,
                longestStreak: viewModel.streakInfo.longestStreak
            ) {
                viewModel.showStreakBreak = false
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showFreezeOffer) {
            FreezeOfferSheet(
                streakCount: viewModel.previousStreakBeforeBreak,
                freezesRemaining: viewModel.streakFreezeCount,
                onUseFreeze: {
                    viewModel.useFreeze()
                    viewModel.showFreezeOffer = false
                    HapticManager.noBuySuccess()
                },
                onDecline: {
                    viewModel.declineFreeze()
                    viewModel.showFreezeOffer = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showChallengeSetup) {
            ChallengeSetupSheet { duration in
                viewModel.startChallenge(duration: duration)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(store: store, entry: paywallEntry)
        }
        .sheet(isPresented: $showImpulseChecklist) {
            ImpulseChecklistScreen()
        }
        .sheet(isPresented: $showUrgeSurfing) {
            UrgeSurfingView()
        }
        .sheet(isPresented: $showWaitingList) {
            WaitingListSheet()
        }
        .sheet(isPresented: $showRatingCard, onDismiss: {
            RatingPrompt.shared.dismissed()
        }) {
            RatingPromptCard(streak: RatingPrompt.shared.milestoneStreak)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showShareCardSheet) {
            if let shareCardImage {
                ShareSheet(items: [shareCardImage, viewModel.shareText])
            }
        }
        .fullScreenCover(isPresented: softPaywallBinding) {
            PaywallView(store: store, entry: .general)
        }
    }

    // MARK: - Reset Today

    private func resetTodayRecord() {
        // Delete every record dated today, not just the cached one — an App
        // Intent race can leave a duplicate that would otherwise survive.
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let todaysRecords = records.filter { calendar.startOfDay(for: $0.date) == today }
        guard !todaysRecords.isEmpty else { return }
        for record in todaysRecords {
            modelContext.delete(record)
        }
        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
            viewModel.todayRecord = nil
            viewModel.loadToday(records: records)
            HapticManager.toggle()
        } catch {
            AppLogger.data.error("Failed to reset today's record: \(error.localizedDescription)")
            viewModel.lastError = "Could not reset today's record. Please try again."
        }
    }

    // MARK: - Milestone Check

    private func checkMilestone() {
        checkMilestoneForStreak(viewModel.streakInfo.currentStreak)
    }

    private func checkMilestoneForStreak(_ streak: Int) {
        guard milestoneDays.contains(streak),
              !store.isPro,
              store.canShowPaywall(atMilestone: true) else { return }
        milestoneDay = streak
        withAnimation { showMilestoneBanner = true }
    }

    // MARK: - Challenge Celebration

    private func checkChallengeCelebration() {
        guard viewModel.isChallengeCompleted else { return }

        // Build a unique key per challenge to celebrate only once
        let challengeKey: String
        if let startDate = viewModel.challengeStartDate {
            let dateStr = startDate.formatted(.iso8601.year().month().day())
            challengeKey = "\(dateStr)_\(viewModel.challengeDuration)"
        } else {
            challengeKey = "unknown_\(viewModel.challengeDuration)"
        }

        let lastCelebrated = UserDefaults.standard.string(forKey: "lastCelebratedChallenge") ?? ""
        guard lastCelebrated != challengeKey else { return }

        // Mark as celebrated
        UserDefaults.standard.set(challengeKey, forKey: "lastCelebratedChallenge")

        // Trigger celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            HapticManager.noBuySuccess()
            SoundManager.playIfEnabled(.milestone)

            withAnimation(DS.Anim.normal) {
                showConfetti = true
                showChallengeCelebration = true
            }

            // Fade-out confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.spring(duration: 0.5, bounce: 0.15)) {
                    showConfetti = false
                }
            }
        }
    }

    // MARK: - Freeze Indicator

    @ViewBuilder
    // MARK: - Today, v2.0.0 (Escapement)
    //
    // Four things, in one order: who today is, where the day stands, the question, and the
    // waits. The question is the ONLY element on the white dial surface (round-2 correction 3);
    // every wait lives in the recessed well at reduced scale, so even in the densest honest
    // state — timer running, two items held, a freeze used — the question still wins the eye.

    /// The date, and the freeze's standing. Both always rendered.
    private var dateHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(Self.headerDateFormatter.string(from: .now))
                .font(.subheadline)
                .foregroundStyle(.inkSecondary)

            Spacer(minLength: DS.Spacing.md)

            HStack(spacing: DS.Spacing.xs) {
                DayMark(truth: .frozen)
                    .accessibilityHidden(true)
                Text(freezeChipText)
                    .font(.caption)
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(.inkSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Freeze: \(viewModel.streakFreezeCount > 0 ? "held" : "used this month")")
        }
    }

    private var freezeChipText: String {
        viewModel.streakFreezeCount > 0 ? "Freeze · held" : "Freeze · used"
    }

    /// The day dial: a 24-hour face whose arc is how much of today has passed, with the count
    /// at its centre. The hand travels the day and SEATS into the midnight index at close —
    /// the product's one expressive beat.
    private func dayDial(now: Date) -> some View {
        let progress = Self.dayProgress(at: now)
        return DialFace(
            size: 266,
            scale: .day,
            progress: progress,
            handPosition: progress
        ) {
            VStack(spacing: 2) {
                Text("\(viewModel.streakInfo.currentStreak)")
                    .font(.system(size: countSize, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.inkPrimary)
                    .contentTransition(.numericText())

                // "1 day kept", not "1 days kept" — the count under the dial is the reader's own
                // number, and this label used to be a ternary whose two branches were the same
                // string, so it never said anything either branch was for.
                Text(viewModel.streakInfo.currentStreak == 1 ? "day kept" : "days kept")
                    .font(.caption)
                    .foregroundStyle(.inkSecondary)

                Text(dialSubline)
                    .font(.caption2)
                    .foregroundStyle(.inkSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DS.Spacing.xxl)
        }
        .animation(reduceMotion ? DS.Anim.beatReduced : DS.Anim.beat, value: viewModel.streakInfo.currentStreak)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(dialAccessibilityText)
    }

    /// First run says what happens tonight rather than showing a zero; afterwards it carries
    /// the best run, which is what the current one is measured against.
    private var dialSubline: String {
        if records.isEmpty { return "the record starts tonight" }
        return "best \(viewModel.streakInfo.longestStreak)"
    }

    private var dialAccessibilityText: String {
        records.isEmpty
            ? "No days kept yet. The record starts tonight."
            : "\(viewModel.streakInfo.currentStreak) days kept, best \(viewModel.streakInfo.longestStreak)"
    }

    /// countXL scales with Dynamic Type and floors at 56 — below that the one heroic number
    /// stops being readable from a hand's length away, which is its whole job.
    private var countSize: CGFloat { max(scaledCount, 56) }

    /// Fixed notice slot. Normally the remainder in words; when a past day was never answered,
    /// the fault notice takes the same slot — attention without alarm, no red anywhere.
    @ViewBuilder
    private func noticeLine(now: Date) -> some View {
        if let error = viewModel.lastError, showErrorBanner {
            noticeRow(glyph: "exclamationmark.triangle", text: error)
        } else {
            Text(Self.remainderText(at: now))
                .font(.footnote)
                .foregroundStyle(.inkSecondary)
                .accessibilityLabel(Self.remainderAccessibilityText(at: now))
        }
    }

    private func noticeRow(glyph: String, text: String) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: glyph)
                .font(.footnote)
                .foregroundStyle(.stateWait)
                .accessibilityHidden(true)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.inkPrimary)
                .multilineTextAlignment(.leading)
        }
        .accessibilityElement(children: .combine)
    }

    /// The question, alone on the one white surface in the screen.
    private var questionSheet: some View {
        VStack(spacing: DS.Spacing.lg) {
            Text("Buy anything unnecessary today?")
                .font(.system(size: max(scaledQuestion, 20), weight: .semibold))
                .foregroundStyle(.inkPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: DS.Spacing.md) {
                answerButton(
                    title: "No",
                    isPrimary: true,
                    identifier: "home_answer_no"
                ) {
                    HapticManager.noBuySuccess()
                    SoundManager.playIfEnabled(.success)
                    viewModel.markNoBuy(context: modelContext, allRecords: records)
                }

                answerButton(
                    title: "Yes",
                    isPrimary: false,
                    identifier: "home_answer_yes"
                ) {
                    HapticManager.tap()
                    viewModel.showSpendOptions = true
                }
            }

            Text("Rent, utilities, transport and groceries never count.")
                .font(.caption)
                .foregroundStyle(.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.sheet)
                .fill(Color.surfaceDial)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.sheet)
                        .strokeBorder(Color.inkHairline, lineWidth: DS.Stroke.hairline)
                )
        )
        // Answered days keep the question in place, disabled — the slot never empties.
        //
        // `.disabled` rather than `.allowsHitTesting(false)`: hit-testing alone stops the taps but
        // says nothing, so VoiceOver kept announcing both buttons as available and reading a
        // question that had already been answered. `.disabled` dims, blocks AND emits the
        // not-enabled trait, and the label below states the fact plus where to change it.
        .opacity(viewModel.isTodayRecorded ? 0.45 : 1)
        .disabled(viewModel.isTodayRecorded)
        .accessibilityElement(children: viewModel.isTodayRecorded ? .ignore : .contain)
        .accessibilityLabel(viewModel.isTodayRecorded
            ? "Today is already answered. Change it in the calendar."
            : "Buy anything unnecessary today?")
        .animation(reduceMotion ? nil : DS.Anim.functional, value: viewModel.isTodayRecorded)
    }

    private func answerButton(
        title: String,
        isPrimary: Bool,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(isPrimary ? Color.inkOnAccent : Color.inkPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule()
                        .fill(isPrimary ? Color.accentKept : Color.surfaceDial)
                        .overlay(
                            Capsule().strokeBorder(
                                isPrimary ? Color.clear : Color.accentSpentText,
                                lineWidth: DS.Stroke.hairline
                            )
                        )
                )
        }
        .buttonStyle(.scale)
        .accessibilityIdentifier(identifier)
    }

    /// The recessed well: three fixed rows. They render whether or not they hold anything,
    /// because a row that vanishes when empty is the "conditional chrome" the grammar forbids.
    private var well: some View {
        VStack(spacing: DS.Stroke.hairline) {
            WellSlotRow(
                glyph: "timer",
                label: "Urge timer",
                detail: "10 minutes, whenever it hits"
            ) {
                Button("Start") { showUrgeSurfing = true }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.accentKept)
                    .accessibilityIdentifier("well_urge_timer")
            }

            WellSlotRow(
                glyph: "hourglass",
                label: waitingLabel,
                detail: waitingDetail
            ) {
                Button(WaitingListManager.shared.activeItems.isEmpty ? "Add" : "Open") {
                    showWaitingList = true
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.accentKept)
                .accessibilityIdentifier("well_waiting_list")
            }

            WellSlotRow(
                glyph: "list.bullet",
                label: "Impulse checklist",
                detail: "five questions before you buy"
            ) {
                Button("Open") { showImpulseChecklist = true }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.accentKept)
                    .accessibilityIdentifier("well_impulse_checklist")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sheet))
    }

    private var waitingLabel: String {
        let count = WaitingListManager.shared.activeItems.count
        return count == 0 ? "Waiting — none held" : "Waiting — \(count) held"
    }

    private var waitingDetail: String {
        guard let first = WaitingListManager.shared.activeItems.first else {
            return "add from a craving"
        }
        return first.name
    }

    /// v1 sections still mounted while their v2 homes are built.
    @ViewBuilder
    private var legacySections: some View {
        VStack(spacing: DS.Spacing.xxl) {
            if !viewModel.savingsGoal.isEmpty {
                savingsGoalCard
            }
            challengeSection
            monthlySummaryCard
        }
    }

    // MARK: - Clock helpers
    //
    // Static and pure so the same arithmetic can be unit-tested without a view, and so the
    // widget can reuse it later without dragging a screen along.

    static func dayProgress(at date: Date, calendar: Calendar = .current) -> Double {
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return 0 }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(max(date.timeIntervalSince(start) / total, 0), 1)
    }

    static func remainderText(at date: Date, calendar: Calendar = .current) -> String {
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return "" }
        let remaining = Int(end.timeIntervalSince(date))
        guard remaining > 0 else { return "The day is closing — a new one is opening" }
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        if hours == 0 { return "\(minutes) m until the day closes" }
        return "\(hours) h \(minutes) m until the day closes"
    }

    static func remainderAccessibilityText(at date: Date, calendar: Calendar = .current) -> String {
        remainderText(at: date, calendar: calendar)
            .replacingOccurrences(of: " h ", with: " hours ")
            .replacingOccurrences(of: " m ", with: " minutes ")
    }

    private static let headerDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "EEEE d MMMM"
        return f
    }()

    // MARK: - Streak Badge

    // MARK: - Savings Goal Card

    private var savingsGoalCard: some View {
        SavingsGoalCard(
            goalLabel: viewModel.savingsGoalLabel,
            goalIcon: viewModel.savingsGoalIcon,
            estimatedSavings: viewModel.formattedEstimatedSavings,
            noBuyDays: viewModel.streakInfo.noBuyDaysThisMonth,
            dailyEstimate: viewModel.dailySpendingEstimate
        )
    }

    // MARK: - Challenge Section

    @ViewBuilder
    private var challengeSection: some View {
        if store.isPro {
            ChallengeCard(
                challengeStartDate: viewModel.challengeStartDate,
                challengeDuration: viewModel.challengeDuration,
                records: records,
                onSetup: { showChallengeSetup = true }
            )
        } else {
            // Pro-locked challenge teaser
            Button {
                paywallEntry = .challenges
                showPaywall = true
            } label: {
                HStack(spacing: DS.Spacing.md) {
                    Image(systemName: "flame")
                        .foregroundStyle(.accentKept.opacity(0.5))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: DS.Spacing.xs) {
                            Text("Challenges")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.inkPrimary)
                            Text(L10n.proBadge)
                                .font(.caption2.bold())
                                .foregroundStyle(.accentKept)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.accentKeptWash))
                        }
                        Text("Set no-spend goals and track progress")
                            .font(.caption)
                            .foregroundStyle(.inkSecondary)
                    }
                    Spacer()
                    // No padlock. The row already says PRO in words; a lock glyph on top of it
                    // is the "you cannot have this" register the design bans, and it sat over a
                    // material blur the token system does not own.
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.inkSecondary)
                }
                .padding(DS.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.lg)
                        .fill(Color.surfaceWell)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.lg)
                                .strokeBorder(Color.inkHairline, lineWidth: DS.Stroke.hairline)
                        )
                )

            }
            .buttonStyle(.scale)
        }
    }

    // MARK: - Monthly Summary

    private var monthlySummaryCard: some View {
        VStack(spacing: DS.Spacing.md) {
            HStack {
                Image(systemName: "chart.bar")
                    .foregroundStyle(.accentKept)
                Text(L10n.thisMonth)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }
            .opacity(summaryAppeared ? 1 : 0)
            .offset(y: summaryAppeared ? 0 : 10)

            HStack(spacing: DS.Spacing.xs) {
                Text("\(viewModel.streakInfo.noBuyDaysThisMonth)")
                    .font(Font.adaptiveDisplay(size: 32, weight: .semibold, isRegular: isRegular))
                    .foregroundStyle(.accentKept)

                Text(L10n.monthSummary(viewModel.streakInfo.noBuyDaysThisMonth, viewModel.streakInfo.totalDaysThisMonth))
                    .font(.callout)
                    .foregroundStyle(.inkSecondary)

                Spacer()

                Text("\(Int(viewModel.streakInfo.noBuyPercentageThisMonth))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.accentKept)
            }
            .opacity(summaryAppeared ? 1 : 0)
            .offset(y: summaryAppeared ? 0 : 10)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.surfaceWell)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentKept)
                        .frame(
                            width: geo.size.width * viewModel.streakInfo.noBuyPercentageThisMonth / 100,
                            height: 8
                        )
                        .animation(reduceMotion ? nil : .spring(duration: 0.5), value: viewModel.streakInfo.noBuyPercentageThisMonth)
                }
            }
            .frame(height: 8)
            .opacity(summaryAppeared ? 1 : 0)
            .accessibilityHidden(true)

            // Estimated savings display
            if viewModel.dailySpendingEstimate > 0 {
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: "leaf")
                        .font(.caption2)
                        .foregroundStyle(.accentKept)
                        .accessibilityHidden(true)
                    Text(String(
                        format: "~$%d saved",
                        Int(viewModel.estimatedSavings)
                    ))
                    .font(.caption)
                    .foregroundStyle(.accentKept)
                    .fontWeight(.medium)
                }
                .opacity(summaryAppeared ? 1 : 0)
                .offset(y: summaryAppeared ? 0 : 10)
            }
        }
        .padding(DS.Spacing.xl)
        .background(Color.surfaceWell, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg)
                .fill(Color.surfaceDial)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("This month: \(viewModel.streakInfo.noBuyDaysThisMonth) no-spend days out of \(viewModel.streakInfo.totalDaysThisMonth), \(Int(viewModel.streakInfo.noBuyPercentageThisMonth)) percent")
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

    // MARK: - Pending Quick Action

    private func consumePendingMarkNoBuy() {
        guard quickActionHandler.pendingMarkNoBuy else { return }
        quickActionHandler.pendingMarkNoBuy = false
        guard !viewModel.isTodayRecorded else { return }
        viewModel.markNoBuy(context: modelContext, allRecords: records)
        checkCelebration()
        RatingPrompt.shared.noteMilestone(currentStreak: viewModel.streakInfo.currentStreak)
    }

    // MARK: - Enhanced Share Card (Pro)

    /// Render the branded streak card and hand it to the share sheet — the
    /// shipped UI behind the paywall's "Enhanced Sharing" promise.
    private func shareEnhancedCard() {
        HapticManager.tap()
        let firstNoBuyDate = records.filter(\.isNoBuyDay).map(\.date).min()
        let renderer = ImageRenderer(content: StreakShareCardPro(
            streakInfo: viewModel.streakInfo,
            savingsGoal: viewModel.savingsGoal,
            firstNoBuyDate: firstNoBuyDate
        ))
        renderer.scale = 3
        if let image = renderer.uiImage {
            shareCardImage = image
            showShareCardSheet = true
        }
    }

    // MARK: - Celebration Check

    private func checkCelebration() {
        let streak = viewModel.streakInfo.currentStreak
        guard Self.celebrationStreaks.contains(streak) else { return }

        // Check achievements and capture newly unlocked
        let totalNoBuyDays = records.count(where: { $0.isNoBuyDay })
        AchievementManager.shared.checkAchievements(
            currentStreak: streak,
            totalNoBuyDays: totalNoBuyDays,
            records: records
        )
        celebrationAchievement = AchievementManager.shared.newlyUnlocked
        if let achievement = celebrationAchievement {
            SpotlightService.indexAchievement(achievement)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(DS.Anim.normal) {
                showConfetti = true
                showMilestoneModal = true
            }
            // Fade-out confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.spring(duration: 0.5, bounce: 0.15)) {
                    showConfetti = false
                }
            }
        }
    }

}

// MARK: - Share Card Surface
//
// v2.0.0: the streak-tiered gradients (rainbow at 100, gold at 30, green below) are gone.
// Two token laws killed them: gradients may not decorate, and an accent may never encode a
// CATEGORY — a colour that changes with the count means the same ink says different things on
// different days. The card is now the dial itself, and the number is the only thing that grows.
