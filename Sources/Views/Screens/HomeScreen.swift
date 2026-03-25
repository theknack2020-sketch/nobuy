import SwiftUI
import SwiftData

struct HomeScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreService.self) private var store
    @Environment(QuickActionHandler.self) private var quickActionHandler
    @Query(sort: \DayRecord.date, order: .reverse) private var records: [DayRecord]
    @State private var viewModel = HomeViewModel()
    @State private var showPaywall = false
    @State private var showShareSheet = false
    @State private var showMilestoneModal = false
    @State private var showConfetti = false
    @State private var summaryAppeared = false
    @State private var showChallengeSetup = false
    @State private var celebrationAchievement: Achievement?
    @State private var showErrorBanner = false
    @State private var isLoading = true
    @State private var sectionsAppeared = false

    private static let celebrationStreaks: Set<Int> = [1, 3, 7, 14, 30, 60, 100]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showMilestoneBanner = false
    @State private var milestoneDay = 0
    @State private var showImpulseChecklist = false
    @State private var showUrgeSurfing = false
    @State private var showChallengeCelebration = false
    @State private var showWaitingList = false
    @State private var showResetConfirmation = false

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
                Color.surfacePrimary
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                ScrollView {
                    VStack(spacing: DS.Spacing.xxl) {
                        Spacer().frame(height: DS.Spacing.lg)

                        // MARK: - Streak Section
                        if records.isEmpty {
                            emptyStateView
                        } else {
                            streakBadge
                                .opacity(sectionsAppeared ? 1 : 0)
                                .offset(y: sectionsAppeared ? 0 : 15)
                                .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 0), value: sectionsAppeared)
                        }

                        // Freeze indicator
                        freezeIndicator
                            .opacity(sectionsAppeared ? 1 : 0)
                            .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 1), value: sectionsAppeared)

                        // MARK: - Action Section
                        mainButton
                            .opacity(sectionsAppeared ? 1 : 0)
                            .offset(y: sectionsAppeared ? 0 : 10)
                            .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 2), value: sectionsAppeared)
                        todayStatus
                            .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                            .opacity(sectionsAppeared ? 1 : 0)
                            .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 3), value: sectionsAppeared)

                        // Error banner
                        if let error = viewModel.lastError, showErrorBanner {
                            errorBanner(message: error)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // MARK: - Goals & Progress Section
                        if !viewModel.savingsGoal.isEmpty {
                            savingsGoalCard
                        }

                        challengeSection

                        // Milestone-based soft paywall banner
                        if showMilestoneBanner && !store.isPro {
                            SoftPaywallBanner(
                                message: L10n.milestonePaywallMessage(milestoneDay),
                                onUpgrade: { showPaywall = true },
                                onDismiss: {
                                    showMilestoneBanner = false
                                    store.trackPaywallDismissed()
                                }
                            )
                        }

                        // MARK: - Stats Section
                        monthlySummaryCard

                        TipCard()
                            .padding(.top, DS.Spacing.sm)

                        // MARK: - Tools Section
                        impulseChecklistButton
                    }
                    .padding(.horizontal, DS.Spacing.xl)
                    .padding(.bottom, DS.Spacing.lg)
                }
                .redacted(reason: isLoading ? .placeholder : [])
                .allowsHitTesting(!isLoading)
                .scrollDismissesKeyboard(.interactively)

                if showMilestoneModal {
                    MilestoneModal(streak: viewModel.streakInfo.currentStreak, achievement: celebrationAchievement) {
                        showMilestoneModal = false
                        AchievementManager.shared.clearNewlyUnlocked()
                        celebrationAchievement = nil
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
                                .foregroundStyle(.noBuyGreen)
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
                                    .foregroundStyle(.noBuyGreen)

                                if WaitingListManager.shared.activeItems.count > 0 {
                                    Text("\(WaitingListManager.shared.activeItems.count)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 16, height: 16)
                                        .background(Circle().fill(Color.spendRed))
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
                                    .foregroundStyle(.noBuyGreen)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.noBuyGreenLight))
                            }
                            .buttonStyle(.scale)
                            .accessibilityLabel("Upgrade to Pro")
                            .accessibilityHint("Double tap to view Pro features")
                            .accessibilityIdentifier("toolbar_pro_badge")
                        }

                        // Share button — basic share for all, enhanced for Pro
                        if viewModel.streakInfo.currentStreak > 0 {
                            ShareLink(
                                item: store.isPro ? viewModel.shareText : "I'm on a \(viewModel.streakInfo.currentStreak)-day no-spend streak! 🔥 #NoBuy",
                                subject: Text("My NoBuy Streak"),
                                message: Text(store.isPro ? viewModel.shareText : "I'm on a \(viewModel.streakInfo.currentStreak)-day no-spend streak!")
                            ) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.noBuyGreen)
                            }
                            .accessibilityLabel(store.isPro ? "Share enhanced streak card" : "Share your streak")
                            .accessibilityHint("Double tap to share your no-spend streak")
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
                Button(L10n.cancel, role: .cancel) { }
            } message: {
                Text("This will remove today's entry. You can re-log it afterwards.")
            }
        }
        .onAppear {
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
                .presentationDetents([.height(280)])
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
        .sheet(isPresented: $showPaywall) {
            PaywallView(store: store)
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
        .sheet(isPresented: softPaywallBinding) {
            PaywallView(store: store)
        }
    }

    // MARK: - Reset Today

    private func resetTodayRecord() {
        guard let record = viewModel.todayRecord else { return }
        modelContext.delete(record)
        do {
            try modelContext.save()
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
                withAnimation(.easeOut(duration: 0.5)) {
                    showConfetti = false
                }
            }
        }
    }

    // MARK: - Freeze Indicator

    @ViewBuilder
    private var freezeIndicator: some View {
        if viewModel.streakInfo.currentStreak > 0 {
            Text(viewModel.freezeDisplayText)
                .font(.caption)
                .foregroundStyle(.textSecondary)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, DS.Spacing.xs)
                .background(
                    Capsule().fill(Color.surfaceSecondary)
                )
                .accessibilityLabel("Streak freeze status: \(viewModel.freezeDisplayText)")
        }
    }

    // MARK: - Streak Badge

    @State private var streakGlowPulse = false

    private var streakBadge: some View {
        VStack(spacing: DS.Spacing.sm) {
            ZStack {
                // Hero glow behind streak number
                if viewModel.streakInfo.currentStreak > 0 {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.noBuyGreen.opacity(0.25), Color.noBuyGreen.opacity(0.05), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 180, height: 180)
                        .scaleEffect(streakGlowPulse ? 1.08 : 0.95)
                        .opacity(streakGlowPulse ? 1 : 0.7)
                        .animation(
                            reduceMotion ? nil : .easeInOut(duration: 2).repeatForever(autoreverses: true),
                            value: streakGlowPulse
                        )
                        .onAppear { streakGlowPulse = true }
                }

                Text("\(viewModel.streakInfo.currentStreak)")
                    .font(.system(size: 80, weight: .black, design: .rounded))
                    .foregroundStyle(viewModel.streakInfo.currentStreak > 0 ? Color.noBuyGreen : Color.textTertiary)
                    .contentTransition(.numericText())
                    .animation(reduceMotion ? nil : .spring(duration: 0.4), value: viewModel.streakInfo.currentStreak)
            }

            Text(L10n.dayStreak)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.textSecondary)
                .textCase(.uppercase)
                .tracking(2)

            if viewModel.streakInfo.longestStreak > 0 {
                Text(L10n.longestStreak(viewModel.streakInfo.longestStreak))
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
        }
        .padding(DS.Spacing.xl)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.xl))
        .shadow(color: viewModel.streakInfo.currentStreak > 0 ? .noBuyGreen.opacity(0.15) : .clear, radius: 16, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(
            format: "%d day streak. Longest streak: %d days",
            viewModel.streakInfo.currentStreak,
            viewModel.streakInfo.longestStreak
        ))
    }

    // MARK: - Main Button

    @ViewBuilder
    private var mainButton: some View {
        VStack(spacing: 0) {
            Button {
                if viewModel.isTodayRecorded && viewModel.isTodayNoBuy {
                    viewModel.showSpendOptions = true
                } else {
                    viewModel.markNoBuy(context: modelContext, allRecords: records)
                    checkCelebration()
                }
            } label: {
                VStack(spacing: DS.Spacing.md) {
                    Image(systemName: viewModel.isTodayNoBuy ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 56))
                        .symbolEffect(.bounce, value: viewModel.isTodayNoBuy)

                    Text(viewModel.isTodayNoBuy ? L10n.noBuyDone : L10n.noBuyButton)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .foregroundStyle(viewModel.isTodayNoBuy ? .white : Color.noBuyGreen)
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.xl)
                        .fill(viewModel.isTodayNoBuy ? Color.noBuyGreen : Color.noBuyGreenLight)
                )
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.xl))
            }
            .buttonStyle(.scale)
            .accessibilityLabel(viewModel.isTodayNoBuy
                ? "Today marked as no-spend"
                : "Mark today as no-spend")
            .accessibilityHint(viewModel.isTodayNoBuy
                ? "Tap to see spending options"
                : "Tap to record a no-spend day")
            .accessibilityIdentifier("main_nobuy_button")
            .contextMenu {
                if viewModel.isTodayRecorded {
                    Button {
                        viewModel.showSpendOptions = true
                    } label: {
                        Label("Change to Spent", systemImage: "cart.fill")
                    }

                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset Today", systemImage: "arrow.counterclockwise")
                    }
                }
            }

            if !viewModel.isTodayRecorded || viewModel.isTodayNoBuy {
                Button {
                    viewModel.showSpendOptions = true
                } label: {
                    Text(L10n.spentButton)
                        .font(.subheadline)
                        .foregroundStyle(.spendRed)
                }
                .buttonStyle(.scale)
                .padding(.top, DS.Spacing.md)
                .accessibilityLabel("I spent today")
                .accessibilityHint("Double tap to log spending for today")
                .accessibilityIdentifier("spent_button")
            }
        }
    }

    // MARK: - Today Status

    private var todayStatus: some View {
        VStack(spacing: DS.Spacing.xs) {
            Text(viewModel.todayStatusText)
                .font(.callout)
                .foregroundStyle(.textSecondary)

            Text(viewModel.todayMotivationalText)
                .font(.caption)
                .foregroundStyle(.textTertiary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today: \(viewModel.todayStatusText). \(viewModel.todayMotivationalText)")
        .animation(reduceMotion ? nil : .easeInOut, value: viewModel.todayStatusText)
    }

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
                showPaywall = true
            } label: {
                HStack(spacing: DS.Spacing.md) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.noBuyGreen.opacity(0.5))
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: DS.Spacing.xs) {
                            Text("Challenges")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.textPrimary)
                            Text(L10n.proBadge)
                                .font(.caption2.bold())
                                .foregroundStyle(.noBuyGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.noBuyGreenLight))
                        }
                        Text("Set no-spend goals and track progress")
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                }
                .padding(DS.Spacing.lg)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.lg)
                        .fill(Color.surfaceSecondary)
                )
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(.scale)
        }
    }

    // MARK: - Monthly Summary

    private var monthlySummaryCard: some View {
        VStack(spacing: DS.Spacing.md) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.noBuyGreen)
                Text(L10n.thisMonth)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }
            .opacity(summaryAppeared ? 1 : 0)
            .offset(y: summaryAppeared ? 0 : 10)

            HStack(spacing: DS.Spacing.xs) {
                Text("\(viewModel.streakInfo.noBuyDaysThisMonth)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.noBuyGreen)

                Text(L10n.monthSummary(viewModel.streakInfo.noBuyDaysThisMonth, viewModel.streakInfo.totalDaysThisMonth))
                    .font(.callout)
                    .foregroundStyle(.textSecondary)

                Spacer()

                Text("\(Int(viewModel.streakInfo.noBuyPercentageThisMonth))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.noBuyGreen)
            }
            .opacity(summaryAppeared ? 1 : 0)
            .offset(y: summaryAppeared ? 0 : 10)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.surfaceTertiary)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.noBuyGreen)
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
                    Image(systemName: "leaf.fill")
                        .font(.caption2)
                        .foregroundStyle(.noBuyGreen)
                        .accessibilityHidden(true)
                    Text(String(
                        format: "~$%d saved",
                        Int(viewModel.estimatedSavings)
                    ))
                        .font(.caption)
                        .foregroundStyle(.noBuyGreen)
                        .fontWeight(.medium)
                }
                .opacity(summaryAppeared ? 1 : 0)
                .offset(y: summaryAppeared ? 0 : 10)
            }
        }
        .padding(DS.Spacing.xl)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg)
                .fill(Color.surfaceSecondary)
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

    // MARK: - Impulse Checklist Button

    private var impulseChecklistButton: some View {
        Button {
            showImpulseChecklist = true
        } label: {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: "checklist")
                    .font(.title3)
                    .foregroundStyle(.noBuyGreen)

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("I want to buy, but...")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.textPrimary)
                    Text("Check before you buy")
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(DS.Spacing.lg)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg)
                    .fill(Color.surfaceSecondary)
            )
        }
        .buttonStyle(.scale)
        .accessibilityLabel("Impulse checklist")
        .accessibilityHint("Double tap to check before you buy")
        .accessibilityIdentifier("impulse_checklist_button")
    }

    // MARK: - Pending Quick Action

    private func consumePendingMarkNoBuy() {
        guard quickActionHandler.pendingMarkNoBuy else { return }
        quickActionHandler.pendingMarkNoBuy = false
        guard !viewModel.isTodayRecorded else { return }
        viewModel.markNoBuy(context: modelContext, allRecords: records)
        checkCelebration()
    }

    // MARK: - Celebration Check

    private func checkCelebration() {
        let streak = viewModel.streakInfo.currentStreak
        guard Self.celebrationStreaks.contains(streak) else { return }

        // Check achievements and capture newly unlocked
        let totalNoBuyDays = records.filter { $0.isNoBuyDay }.count
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
                withAnimation(.easeOut(duration: 0.5)) {
                    showConfetti = false
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: DS.Spacing.lg) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.noBuyGreen.opacity(0.6))
                .symbolEffect(.pulse, options: reduceMotion ? .nonRepeating : .repeating)
                .accessibilityHidden(true)

            VStack(spacing: DS.Spacing.sm) {
                Text(L10n.emptyHomeTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.textPrimary)

                Text(L10n.emptyHomeDesc)
                    .font(.callout)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Error Banner

    private func errorBanner(message: String) -> some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.spendRed)
                .font(.callout)

            Text(message)
                .font(.caption)
                .foregroundStyle(.textPrimary)
                .lineLimit(2)

            Spacer()

            Button {
                withAnimation {
                    viewModel.dismissError()
                    showErrorBanner = false
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.textTertiary)
                    .font(.callout)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("Dismiss error")
            .accessibilityIdentifier("dismiss_error")
        }
        .padding(DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .fill(Color.spendRed.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.md)
                        .stroke(Color.spendRed.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Share Card Gradient Helpers

private extension Int {
    /// Gradient colors based on streak length
    var shareCardGradient: [Color] {
        switch self {
        case 100...:
            // Rainbow/prismatic for legendary 100+ streaks
            return [
                Color(red: 0.55, green: 0.27, blue: 0.68),
                Color(red: 0.27, green: 0.50, blue: 0.78),
                Color(red: 0.27, green: 0.63, blue: 0.45),
                Color(red: 0.92, green: 0.75, blue: 0.28),
            ]
        case 30...:
            // Gold gradient for 30+ streaks
            return [
                Color(red: 0.76, green: 0.60, blue: 0.20),
                Color(red: 0.92, green: 0.78, blue: 0.38),
                Color(red: 0.76, green: 0.60, blue: 0.20),
            ]
        default:
            // Green gradient for early streaks
            return [
                Color(red: 0.20, green: 0.52, blue: 0.38),
                Color(red: 0.32, green: 0.72, blue: 0.52),
                Color(red: 0.20, green: 0.52, blue: 0.38),
            ]
        }
    }

    var shareCardDarkGradient: [Color] {
        switch self {
        case 100...:
            return [
                Color(red: 0.15, green: 0.10, blue: 0.22),
                Color(red: 0.10, green: 0.15, blue: 0.25),
                Color(red: 0.10, green: 0.20, blue: 0.18),
                Color(red: 0.22, green: 0.18, blue: 0.08),
            ]
        case 30...:
            return [
                Color(red: 0.18, green: 0.14, blue: 0.05),
                Color(red: 0.25, green: 0.20, blue: 0.08),
                Color(red: 0.18, green: 0.14, blue: 0.05),
            ]
        default:
            return [
                Color(red: 0.06, green: 0.16, blue: 0.12),
                Color(red: 0.10, green: 0.22, blue: 0.16),
                Color(red: 0.06, green: 0.16, blue: 0.12),
            ]
        }
    }

    var shareCardEmoji: String {
        switch self {
        case 100...: return "💯"
        case 60...: return "👑"
        case 30...: return "🏆"
        case 14...: return "⭐"
        case 7...: return "🔥"
        default: return "🌱"
        }
    }
}

private func formattedStartDate(_ date: Date?) -> String? {
    guard let date else { return nil }
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}

private func localizedGoalText(_ goal: String) -> String? {
    guard !goal.isEmpty else { return nil }
    switch goal {
    case "emergencyFund": return L10n.goalEmergencyFund
    case "vacation": return L10n.goalVacation
    case "debtFree": return L10n.goalDebtFree
    case "discipline": return L10n.goalDiscipline
    default: return goal
    }
}

// MARK: - Streak Share Card (Basic)

struct StreakShareCard: View {
    let streakInfo: StreakInfo
    var savingsGoal: String = ""
    var firstNoBuyDate: Date? = nil

    @Environment(\.colorScheme) private var colorScheme

    private var gradientColors: [Color] {
        colorScheme == .dark
            ? streakInfo.currentStreak.shareCardDarkGradient
            : streakInfo.currentStreak.shareCardGradient
    }

    private var textColor: Color {
        .white
    }

    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer().frame(height: DS.Spacing.md)

            // Emoji
            Text(streakInfo.currentStreak.shareCardEmoji)
                .font(.system(size: 52))

            // Streak number
            Text("\(streakInfo.currentStreak)")
                .font(.system(size: 80, weight: .black, design: .rounded))
                .foregroundStyle(textColor)

            // "DAY STREAK"
            Text(L10n.shareStreakDays)
                .font(.headline)
                .tracking(3)
                .foregroundStyle(textColor.opacity(0.8))

            // Start date
            if let dateStr = formattedStartDate(firstNoBuyDate) {
                Text(L10n.shareSince(dateStr))
                    .font(.caption)
                    .foregroundStyle(textColor.opacity(0.6))
            }

            // Savings goal
            if let goalText = localizedGoalText(savingsGoal) {
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: "target")
                        .font(.caption2)
                    Text(goalText)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(textColor.opacity(0.7))
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.vertical, DS.Spacing.xs)
                .background(
                    Capsule()
                        .fill(textColor.opacity(0.15))
                )
            }

            Spacer()

            // Bottom CTA
            VStack(spacing: DS.Spacing.xs) {
                Rectangle()
                    .fill(textColor.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, DS.Spacing.xxxl)

                Text(L10n.shareNoBuy)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(textColor.opacity(0.7))

                Text("Download NoBuy on the App Store")
                    .font(.caption2)
                    .foregroundStyle(textColor.opacity(0.45))
            }

            Spacer().frame(height: DS.Spacing.lg)
        }
        .frame(width: 360, height: 480)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.xl)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        )
    }
}

// MARK: - Streak Share Card (Pro)

struct StreakShareCardPro: View {
    let streakInfo: StreakInfo
    var savingsGoal: String = ""
    var firstNoBuyDate: Date? = nil

    @Environment(\.colorScheme) private var colorScheme

    private var gradientColors: [Color] {
        colorScheme == .dark
            ? streakInfo.currentStreak.shareCardDarkGradient
            : streakInfo.currentStreak.shareCardGradient
    }

    private var textColor: Color {
        .white
    }

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            // PRO badge
            HStack {
                Spacer()
                Text(L10n.proBadge)
                    .font(.caption2.bold())
                    .foregroundStyle(gradientColors.first ?? .noBuyGreen)
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(textColor.opacity(0.9))
                    )
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.top, DS.Spacing.lg)

            // Emoji
            Text(streakInfo.currentStreak.shareCardEmoji)
                .font(.system(size: 52))

            // Streak number
            Text("\(streakInfo.currentStreak)")
                .font(.system(size: 80, weight: .black, design: .rounded))
                .foregroundStyle(textColor)

            // "DAY STREAK"
            Text(L10n.shareStreakDays)
                .font(.headline)
                .tracking(3)
                .foregroundStyle(textColor.opacity(0.8))

            // Start date
            if let dateStr = formattedStartDate(firstNoBuyDate) {
                Text(L10n.shareSince(dateStr))
                    .font(.caption)
                    .foregroundStyle(textColor.opacity(0.6))
            }

            // Savings goal
            if let goalText = localizedGoalText(savingsGoal) {
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: "target")
                        .font(.caption2)
                    Text(goalText)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(textColor.opacity(0.7))
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.vertical, DS.Spacing.xs)
                .background(
                    Capsule()
                        .fill(textColor.opacity(0.15))
                )
            }

            // Stats row
            HStack(spacing: DS.Spacing.xxxl) {
                VStack(spacing: DS.Spacing.xs) {
                    Text("\(streakInfo.longestStreak)")
                        .font(.title3.bold())
                        .foregroundStyle(textColor)
                    Text(L10n.shareLongest)
                        .font(.caption2)
                        .foregroundStyle(textColor.opacity(0.6))
                }
                VStack(spacing: DS.Spacing.xs) {
                    Text("\(Int(streakInfo.noBuyPercentageThisMonth))%")
                        .font(.title3.bold())
                        .foregroundStyle(textColor)
                    Text(L10n.shareThisMonth)
                        .font(.caption2)
                        .foregroundStyle(textColor.opacity(0.6))
                }
            }
            .padding(.top, DS.Spacing.sm)

            Spacer()

            // Bottom CTA
            VStack(spacing: DS.Spacing.xs) {
                Rectangle()
                    .fill(textColor.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, DS.Spacing.xxxl)

                Text(L10n.shareNoBuy)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(textColor.opacity(0.7))

                Text("Download NoBuy on the App Store")
                    .font(.caption2)
                    .foregroundStyle(textColor.opacity(0.45))
            }

            Spacer().frame(height: DS.Spacing.lg)
        }
        .frame(width: 360, height: 560)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.xl)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
        )
    }
}

#Preview {
    HomeScreen()
        .environment(StoreService.shared)
        .environment(QuickActionHandler())
        .modelContainer(for: [DayRecord.self, MandatoryCategory.self], inMemory: true)
}
