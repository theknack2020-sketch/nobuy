import SwiftUI
import UserNotifications

struct OnboardingScreen: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("savingsGoal") private var savingsGoal: String = ""
    @AppStorage("dailySpendingEstimate") private var dailySpendingEstimate: Double = 0
    @State private var currentPage = 0
    @State private var selectedGoal: SavingsGoal? = nil
    @State private var customGoalText: String = ""
    @State private var spendingInput: String = ""
    @State private var notificationPermissionGranted = false
    @State private var direction: Int = 1 // 1 = forward, -1 = back
    @State private var showPaywall = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    private let totalPages = 5

    enum SavingsGoal: String, CaseIterable, Identifiable {
        case emergencyFund
        case vacation
        case debtFree
        case discipline
        case custom

        var id: String {
            rawValue
        }

        var label: String {
            switch self {
            case .emergencyFund: L10n.goalEmergencyFund
            case .vacation: L10n.goalVacation
            case .debtFree: L10n.goalDebtFree
            case .discipline: L10n.goalDiscipline
            case .custom: L10n.goalCustom
            }
        }

        var icon: String {
            switch self {
            case .emergencyFund: "shield.fill"
            case .vacation: "airplane"
            case .debtFree: "creditcard.trianglebadge.exclamationmark"
            case .discipline: "brain.head.profile"
            case .custom: "pencil.line"
            }
        }

        var color: Color {
            switch self {
            case .emergencyFund: .blue
            case .vacation: .orange
            case .debtFree: .noBuyGreen
            case .discipline: .purple
            case .custom: .textSecondary
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Content
            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                howItWorksPage.tag(1)
                streaksPage.tag(2)
                goalSettingPage.tag(3)
                notificationsPage.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.2), value: currentPage)

            // Page indicator
            HStack(spacing: DS.Spacing.sm) {
                ForEach(0 ..< totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.noBuyGreen : Color.textTertiary.opacity(0.4))
                        .frame(width: index == currentPage ? DS.Spacing.xxl : DS.Spacing.sm, height: DS.Spacing.sm)
                        .animation(reduceMotion ? nil : .spring(duration: 0.3, bounce: 0.3), value: currentPage)
                }
            }
            .padding(.bottom, DS.Spacing.xxl + DS.Spacing.xs)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Page \(currentPage + 1) of \(totalPages)")

            // Action button
            Button {
                advancePage()
            } label: {
                Text(buttonLabel)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.lg)
                            .fill(Color.noBuyGreen)
                    )
            }
            .buttonStyle(.scale)
            .padding(.horizontal, DS.Spacing.xxl)
            .padding(.bottom, DS.Spacing.md)
            .accessibilityIdentifier("onboarding_next_button")

            // Skip / Maybe Later
            if currentPage < totalPages - 1 {
                Button {
                    completeOnboarding()
                } label: {
                    Text(L10n.skip)
                        .font(.subheadline)
                        .foregroundStyle(.textTertiary)
                }
                .buttonStyle(.scale)
                .padding(.bottom, DS.Spacing.xxl)
                .accessibilityLabel("Skip onboarding")
            } else {
                // On notification page, offer "Maybe Later" as skip
                Button {
                    completeOnboarding()
                } label: {
                    Text(L10n.maybeLater)
                        .font(.subheadline)
                        .foregroundStyle(.textTertiary)
                }
                .buttonStyle(.scale)
                .padding(.bottom, DS.Spacing.xxl)
            }
        }
        .background(
            LinearGradient(
                colors: [Color.noBuyGreen.opacity(0.15), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
    }

    // MARK: - Button Label

    private var buttonLabel: String {
        switch currentPage {
        case 4:
            notificationPermissionGranted ? L10n.getStarted : L10n.enableNotifications
        case 3:
            L10n.next
        default:
            currentPage < totalPages - 1 ? L10n.next : L10n.getStarted
        }
    }

    // MARK: - Page Advance Logic

    private func advancePage() {
        HapticManager.impact(.light)

        if currentPage == 3 {
            persistGoal()
        }

        if currentPage == 4 {
            if !notificationPermissionGranted {
                requestNotifications()
                return
            } else {
                completeOnboarding()
                return
            }
        }

        if currentPage < totalPages - 1 {
            direction = 1
            withAnimation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.2)) {
                currentPage += 1
            }
        }
    }

    private func persistGoal() {
        if let goal = selectedGoal {
            if goal == .custom {
                savingsGoal = customGoalText.isEmpty ? goal.rawValue : customGoalText
            } else {
                savingsGoal = goal.rawValue
            }
        }
        if let value = Double(spendingInput.replacingOccurrences(of: ",", with: ".")) {
            dailySpendingEstimate = value
        }
    }

    private func requestNotifications() {
        Task {
            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run {
                    notificationPermissionGranted = granted
                    if granted {
                        HapticManager.impact(.medium)
                        // Schedule the daily reminder via NotificationManager
                        Task {
                            await NotificationManager().scheduleDailyReminder(hour: 21, minute: 0)
                        }
                        // Auto-advance after granting
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            completeOnboarding()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    completeOnboarding()
                }
            }
        }
    }

    private func completeOnboarding() {
        persistGoal()
        HapticManager.impact(.medium)

        // Schedule Day 1-3 onboarding journey push notifications
        Task {
            await NotificationManager().scheduleOnboardingJourney()
        }

        withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.2)) {
            hasCompletedOnboarding = true
        }
    }

    // MARK: - Brand Mark (consistent across all pages)

    private var brandMark: some View {
        HStack(spacing: 6) {
            ZStack {
                Image(systemName: "bag.fill")
                    .font(Font.adaptiveDetail(isRegular: isRegular).weight(.medium))
                Image(systemName: "line.diagonal")
                    .font(Font.adaptiveHeadline(isRegular: isRegular).weight(.bold))
            }
            .foregroundStyle(.white.opacity(0.5))
            Text("NoBuy")
                .font(Font.adaptiveCaption(isRegular: isRegular).weight(.semibold))
                .foregroundStyle(.white.opacity(0.4))
        }
        .accessibilityHidden(true)
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: DS.Spacing.xxl) {
            brandMark
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.noBuyGreen.opacity(0.12))
                    .frame(width: 160, height: 160)

                Image(systemName: "heart.circle.fill")
                    .font(Font.adaptiveDisplay(size: 80, isRegular: isRegular))
                    .foregroundStyle(.noBuyGreen)
                    .symbolEffect(.pulse, options: reduceMotion ? .nonRepeating : .repeating)
                    .accessibilityHidden(true)
            }

            VStack(spacing: DS.Spacing.md) {
                Text(L10n.onboardingTitle1)
                    .font(Font.adaptiveDisplay(size: 26, weight: .bold, design: .rounded, isRegular: isRegular))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.lg)

                Text(L10n.onboardingDesc1)
                    .font(.body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xxxl)
                    .lineSpacing(4)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Page 2: How It Works

    private var howItWorksPage: some View {
        VStack(spacing: DS.Spacing.xxl) {
            brandMark
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 160, height: 160)

                Image(systemName: "hand.tap.fill")
                    .font(Font.adaptiveDisplay(size: 80, isRegular: isRegular))
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse, options: reduceMotion ? .nonRepeating : .repeating)
                    .accessibilityHidden(true)
            }

            VStack(spacing: DS.Spacing.md) {
                Text(L10n.onboardingTitle2)
                    .font(Font.adaptiveDisplay(size: 26, weight: .bold, design: .rounded, isRegular: isRegular))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.lg)

                Text(L10n.onboardingDesc2)
                    .font(.body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xxxl)
                    .lineSpacing(4)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Page 3: Streaks & Milestones

    private var streaksPage: some View {
        VStack(spacing: DS.Spacing.xxl) {
            brandMark
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 160, height: 160)

                Image(systemName: "flame.fill")
                    .font(Font.adaptiveDisplay(size: 80, isRegular: isRegular))
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse, options: reduceMotion ? .nonRepeating : .repeating)
                    .accessibilityHidden(true)
            }

            VStack(spacing: DS.Spacing.md) {
                Text(L10n.onboardingTitle3)
                    .font(Font.adaptiveDisplay(size: 26, weight: .bold, design: .rounded, isRegular: isRegular))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.lg)

                Text(L10n.onboardingDesc3)
                    .font(.body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xxxl)
                    .lineSpacing(4)
            }

            // Mini milestone preview
            HStack(spacing: DS.Spacing.lg) {
                milestonePill(days: 7, icon: "trophy.fill", color: .blue)
                milestonePill(days: 30, icon: "crown.fill", color: .orange)
                milestonePill(days: 100, icon: "star.circle.fill", color: .purple)
            }
            .padding(.top, DS.Spacing.sm)

            Spacer()
            Spacer()
        }
    }

    private func milestonePill(days: Int, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text("\(days)")
                .font(Font.adaptiveSubheadline(isRegular: isRegular).weight(.bold))
                .minimumScaleFactor(0.8)
                .foregroundStyle(.textPrimary)
            Text(L10n.dayStreak)
                .font(.caption2)
                .foregroundStyle(.textTertiary)
        }
        .padding(.vertical, DS.Spacing.md)
        .padding(.horizontal, DS.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .fill(color.opacity(0.1))
        )
    }

    // MARK: - Page 4: Goal Setting

    private var goalSettingPage: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.xl) {
                brandMark
                Spacer().frame(height: DS.Spacing.lg)

                Image(systemName: "target")
                    .font(Font.adaptiveDisplay(size: 48, isRegular: isRegular))
                    .foregroundStyle(.noBuyGreen)

                VStack(spacing: DS.Spacing.sm) {
                    Text(L10n.onboardingTitle4)
                        .font(Font.adaptiveDisplay(size: 26, weight: .bold, design: .rounded, isRegular: isRegular))
                        .multilineTextAlignment(.center)

                    Text(L10n.onboardingDesc4)
                        .font(.body)
                        .foregroundStyle(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.lg)
                }

                // Goal options
                VStack(spacing: 10) {
                    ForEach(SavingsGoal.allCases) { goal in
                        Button {
                            withAnimation(reduceMotion ? nil : .spring(duration: 0.3, bounce: 0.2)) {
                                selectedGoal = goal
                            }
                            HapticManager.impact(.light)
                        } label: {
                            HStack(spacing: DS.Spacing.md) {
                                Image(systemName: goal.icon)
                                    .font(.body)
                                    .foregroundStyle(selectedGoal == goal ? .white : goal.color)
                                    .frame(width: DS.Spacing.xxxl)

                                Text(goal.label)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(selectedGoal == goal ? .white : .textPrimary)

                                Spacer()

                                if selectedGoal == goal {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.white)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, DS.Spacing.lg)
                            .padding(.vertical, DS.Spacing.lg - 2)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.md)
                                    .fill(selectedGoal == goal ? Color.noBuyGreen : Color.surfaceSecondary)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DS.Spacing.xxl)

                // Custom goal text field
                if selectedGoal == .custom {
                    TextField(L10n.goalCustomPlaceholder, text: $customGoalText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, DS.Spacing.xxl)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Daily spending estimate (optional)
                VStack(spacing: DS.Spacing.sm) {
                    HStack {
                        Text(L10n.dailySpendingLabel)
                            .font(.subheadline)
                            .foregroundStyle(.textSecondary)
                        Text("(\(L10n.optional))")
                            .font(.caption)
                            .foregroundStyle(.textTertiary)
                    }

                    TextField(L10n.dailySpendingPlaceholder, text: $spendingInput)
                        .keyboardType(.decimalPad)
                        .font(Font.adaptiveTitle3(isRegular: isRegular).weight(.semibold))
                        .multilineTextAlignment(.center)
                        .padding(.vertical, DS.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                .fill(Color.surfaceSecondary)
                        )

                    Text(L10n.dailySpendingHint)
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                }
                .padding(.horizontal, DS.Spacing.xxl)
                .padding(.top, DS.Spacing.sm)

                Spacer().frame(height: 60)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Page 5: Notifications

    private var notificationsPage: some View {
        VStack(spacing: DS.Spacing.xxl) {
            brandMark
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.mandatoryAmber.opacity(0.12))
                    .frame(width: 160, height: 160)

                Image(systemName: "bell.badge.fill")
                    .font(Font.adaptiveDisplay(size: 80, isRegular: isRegular))
                    .foregroundStyle(.mandatoryAmber)
            }

            VStack(spacing: DS.Spacing.md) {
                Text(L10n.onboardingTitle5)
                    .font(Font.adaptiveDisplay(size: 26, weight: .bold, design: .rounded, isRegular: isRegular))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.lg)

                Text(L10n.onboardingDesc5)
                    .font(.body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xxxl)
                    .lineSpacing(4)
            }

            // Notification preview mockup
            notificationPreview

            // Subtle Pro mention
            proTrialCTA

            Spacer()
            Spacer()
        }
    }

    // MARK: - Pro Trial CTA

    private var proTrialCTA: some View {
        Button {
            HapticManager.impact(.light)
            showPaywall = true
        } label: {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundStyle(.noBuyGreen)

                Text("Unlock all features with Pro")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.textTertiary)
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.vertical, DS.Spacing.sm + 2)
            .background(
                Capsule()
                    .fill(Color.noBuyGreenLight)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(store: .shared)
        }
    }

    private var notificationPreview: some View {
        HStack(spacing: DS.Spacing.md) {
            RoundedRectangle(cornerRadius: DS.Radius.sm)
                .fill(Color.noBuyGreen)
                .frame(width: DS.Spacing.huge, height: DS.Spacing.huge)
                .overlay(
                    Text("N")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("NoBuy")
                    .font(.caption.bold())
                    .foregroundStyle(.textPrimary)
                Text(L10n.notifDailyReminder1)
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer()

            Text("21:00")
                .font(.caption2)
                .foregroundStyle(.textTertiary)
        }
        .padding(DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg)
                .fill(Color.surfaceSecondary)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
        .padding(.horizontal, DS.Spacing.huge)
    }
}

#Preview {
    OnboardingScreen()
}
