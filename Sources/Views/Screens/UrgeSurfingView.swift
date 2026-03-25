import SwiftUI
import UserNotifications

// MARK: - Urge Surfing View
// 10-minute mindfulness timer to ride out an impulse-buy urge.
// Accessible from HomeScreen toolbar.
// Uses Date-based elapsed calculation so backgrounding doesn't lose time.

struct UrgeSurfingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("savingsGoal") private var savingsGoal: String = ""

    private let totalSeconds: Int = 600 // 10 minutes
    private let promptInterval: Int = 120 // rotate every 2 minutes

    // MARK: - Timer State (Date-based)
    @State private var startTime: Date?
    @State private var pausedElapsed: TimeInterval = 0
    @State private var displayTick: Int = 0 // drives UI updates
    @State private var timer: Timer?
    @State private var isRunning = false
    @State private var isCompleted = false
    @State private var showConfetti = false
    @State private var currentPromptIndex = 0
    @State private var promptOpacity: Double = 1.0

    // MARK: - Breathing Animation State
    @State private var breathPhase: BreathPhase = .inhale

    private enum BreathPhase: CaseIterable {
        case inhale, hold, exhale

        var label: String {
            switch self {
            case .inhale: "Breathe in..."
            case .hold:   "Hold..."
            case .exhale: "Breathe out..."
            }
        }

        var scale: CGFloat {
            switch self {
            case .inhale: 1.0
            case .hold:   1.0
            case .exhale: 0.6
            }
        }

        var next: BreathPhase {
            switch self {
            case .inhale: .hold
            case .hold:   .exhale
            case .exhale: .inhale
            }
        }
    }

    // MARK: - Notification Identifier
    private static let completionNotificationID = "urge_surfing_completion"

    // MARK: - Prompts

    private var prompts: [String] {
        [
            "Take a deep breath. This feeling is temporary.",
            "Close your eyes and count to 10.",
            "Why do you want to buy this? Is it a real need?",
            "Would you still spend this money a week from now?",
            goalPrompt,
        ]
    }

    private var goalPrompt: String {
        let goalText = resolvedGoalText
        return "Stay focused on your goal. You're saving for \(goalText)."
    }

    private var resolvedGoalText: String {
        if savingsGoal.isEmpty {
            return "Your Goal"
        }
        switch savingsGoal {
        case "emergencyFund":
            return "Emergency Fund"
        case "vacation":
            return "Vacation"
        case "debtFree":
            return "Debt-Free Life"
        case "discipline":
            return "Discipline"
        default:
            return savingsGoal
        }
    }

    // MARK: - Computed Timer Values

    /// Elapsed seconds based on wall-clock time, surviving background
    private var elapsedSeconds: Int {
        guard let start = startTime else { return Int(pausedElapsed) }
        if isRunning {
            return Int(Date().timeIntervalSince(start) + pausedElapsed)
        }
        return Int(pausedElapsed)
    }

    private var remainingSeconds: Int {
        max(0, totalSeconds - elapsedSeconds)
    }

    private var progress: CGFloat {
        CGFloat(elapsedSeconds) / CGFloat(totalSeconds)
    }

    private var timeString: String {
        let remaining = remainingSeconds
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePrimary.ignoresSafeArea()

                if isCompleted {
                    completionView
                        .transition(.scale.combined(with: .opacity))
                } else {
                    timerView
                        .transition(.opacity)
                }

                if showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                        .zIndex(10)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        HapticManager.tap()
                        stopTimer()
                        cancelCompletionNotification()
                        dismiss()
                    }
                    .accessibilityIdentifier("urge_surfing_close")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onDisappear {
            stopTimer()
            cancelCompletionNotification()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && isRunning {
                // Force a tick to catch up elapsed time from background
                displayTick += 1
                checkCompletion()
            }
        }
    }

    // MARK: - Timer View

    private var timerView: some View {
        VStack(spacing: DS.Spacing.xxxl) {
            Spacer()

            // Title with gradient
            Text("Urge Surfing")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.textPrimary, .textSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .accessibilityAddTraits(.isHeader)

            // Circular progress ring + timer
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.noBuyGreen.opacity(0.15), lineWidth: 12)
                    .frame(width: 220, height: 220)
                    .shadow(color: .noBuyGreen.opacity(0.05), radius: 8, x: 0, y: 4)

                // Progress ring with gradient
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.noBuyGreen, .green.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(reduceMotion ? nil : .linear(duration: 1), value: progress)
                    .shadow(color: .noBuyGreen.opacity(0.2), radius: 6, x: 0, y: 3)

                // Time display
                VStack(spacing: DS.Spacing.xs) {
                    Text(timeString)
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(.noBuyGreen)
                        .contentTransition(.numericText())
                        .animation(reduceMotion ? nil : .linear(duration: 0.3), value: remainingSeconds)

                    Text("remaining")
                        .font(.caption)
                        .foregroundStyle(.textTertiary)
                        .textCase(.uppercase)
                        .tracking(2)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(timeString) remaining")
            .accessibilityValue("\(Int(progress * 100)) percent complete")

            // Breathing animation (between ring and prompt)
            breathingView
                .frame(height: 80)
                .padding(.top, -DS.Spacing.md)

            // Mindfulness prompt
            Text(prompts[currentPromptIndex])
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xxxl)
                .opacity(promptOpacity)
                .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7), value: promptOpacity)
                .id("prompt-\(currentPromptIndex)")

            Spacer()

            // Start / Pause button
            Button {
                if isRunning {
                    pauseTimer()
                } else {
                    startTimer()
                }
            } label: {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title3)
                    Text(isRunning
                         ? "Pause"
                         : (startTime == nil && pausedElapsed == 0
                            ? "Start"
                            : "Continue"))
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.lg)
                        .fill(
                            LinearGradient(
                                colors: [.noBuyGreen, .noBuyGreen.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: .noBuyGreen.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.scale)
            .padding(.horizontal, DS.Spacing.xxl)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: isRunning)
            .accessibilityLabel(isRunning ? "Pause timer" : (startTime == nil && pausedElapsed == 0 ? "Start timer" : "Continue timer"))
            .accessibilityHint(isRunning ? "Double tap to pause" : "Double tap to start the 10 minute timer")
            .accessibilityIdentifier("urge_surfing_toggle")

            // Reset button (only shown when paused and not at start)
            if !isRunning && (startTime != nil || pausedElapsed > 0) {
                Button {
                    HapticManager.tap()
                    resetTimer()
                } label: {
                    Text("Reset")
                        .font(.subheadline)
                        .foregroundStyle(.textTertiary)
                }
                .accessibilityLabel("Reset timer")
                .accessibilityHint("Double tap to reset the urge surfing timer")
            }

            Spacer()
                .frame(height: DS.Spacing.xxl)
        }
    }

    // MARK: - Breathing View

    @ViewBuilder
    private var breathingView: some View {
        if isRunning {
            if reduceMotion {
                // Static fallback for reduced motion
                Text("Take a deep breath")
                    .font(.subheadline)
                    .foregroundStyle(.noBuyGreen.opacity(0.7))
            } else {
                VStack(spacing: DS.Spacing.sm) {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.noBuyGreen.opacity(0.3), .noBuyGreen.opacity(0.05)],
                                center: .center,
                                startRadius: 2,
                                endRadius: 20
                            )
                        )
                        .frame(width: 40, height: 40)
                        .scaleEffect(breathPhase == .exhale ? 0.6 : 1.0)
                        .shadow(color: .noBuyGreen.opacity(0.15), radius: 4, x: 0, y: 2)
                        .animation(.easeInOut(duration: 4), value: breathPhase)

                    Text(breathPhase.label)
                        .font(.subheadline)
                        .foregroundStyle(.noBuyGreen.opacity(0.7))
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.5), value: breathPhase)
                }
            }
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: DS.Spacing.xxxl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.noBuyGreen.opacity(0.2), .noBuyGreen.opacity(0.02)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: "medal.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.noBuyGreen, .green.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .noBuyGreen.opacity(0.4), radius: 10, x: 0, y: 5)
            }

            VStack(spacing: DS.Spacing.md) {
                Text("You beat the urge! 🎉")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("You stayed strong for 10 minutes. This urge is now behind you.")
                    .font(.body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xxxl)

                let survivedCount = UserDefaults.standard.integer(forKey: "urgesSurvivedCount")
                Text("You've beaten \(survivedCount) urges total")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(.noBuyGreen)
                .padding(.top, DS.Spacing.sm)
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.vertical, DS.Spacing.sm)
                .background(
                    Capsule()
                        .fill(Color.noBuyGreenLight)
                )
                .shadow(color: .noBuyGreen.opacity(0.1), radius: 4, x: 0, y: 2)
            }

            Spacer()

            VStack(spacing: DS.Spacing.md) {
                Button {
                    HapticManager.tap()
                    SoundManager.playIfEnabled(.tap)
                    dismiss()
                } label: {
                    Text("Awesome! 💪")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.lg)
                                .fill(
                                    LinearGradient(
                                        colors: [.noBuyGreen, .noBuyGreen.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: .noBuyGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.scale)
                .accessibilityLabel("Done, close urge surfing")
                .accessibilityIdentifier("urge_surfing_done")

                Button {
                    HapticManager.tap()
                    restartTimer()
                } label: {
                    Text("Start again")
                        .font(.subheadline)
                        .foregroundStyle(.textTertiary)
                }
            }
            .padding(.horizontal, DS.Spacing.xxl)
            .padding(.bottom, DS.Spacing.xxxl)
        }
    }

    // MARK: - Timer Logic (Date-based)

    private func startTimer() {
        isRunning = true
        startTime = Date()
        HapticManager.tap()
        SoundManager.playIfEnabled(.tap)

        // Schedule background completion notification
        scheduleCompletionNotification(secondsRemaining: TimeInterval(totalSeconds) - pausedElapsed)

        // Start breathing cycle
        startBreathingCycle()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                guard isRunning else { return }
                displayTick += 1
                checkPromptRotation()
                checkCompletion()
            }
        }
    }

    private func checkCompletion() {
        if remainingSeconds <= 0 {
            completeTimer()
        }
    }

    private func checkPromptRotation() {
        let elapsed = elapsedSeconds
        let expectedIndex = elapsed > 0 ? min(elapsed / promptInterval, prompts.count - 1) : 0
        if expectedIndex != currentPromptIndex {
            rotatePrompt(to: expectedIndex)
        }
    }

    private func pauseTimer() {
        // Capture elapsed time so far
        if let start = startTime {
            pausedElapsed += Date().timeIntervalSince(start)
        }
        startTime = nil
        isRunning = false
        timer?.invalidate()
        timer = nil
        cancelCompletionNotification()
        HapticManager.soft()
    }

    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func resetTimer() {
        stopTimer()
        cancelCompletionNotification()
        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7)) {
            startTime = nil
            pausedElapsed = 0
            displayTick = 0
            currentPromptIndex = 0
            promptOpacity = 1.0
            breathPhase = .inhale
        }
    }

    private func restartTimer() {
        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7)) {
            isCompleted = false
            showConfetti = false
            startTime = nil
            pausedElapsed = 0
            displayTick = 0
            currentPromptIndex = 0
            promptOpacity = 1.0
            breathPhase = .inhale
        }
    }

    private func completeTimer() {
        stopTimer()
        cancelCompletionNotification()

        // Track urge survived
        let key = "urgesSurvivedCount"
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + 1, forKey: key)

        HapticManager.celebration()
        SoundManager.playIfEnabled(.celebration)

        withAnimation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.65)) {
            isCompleted = true
            showConfetti = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showConfetti = false
        }
    }

    private func rotatePrompt(to index: Int) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8)) {
            promptOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentPromptIndex = index
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7)) {
                promptOpacity = 1.0
            }
        }

        HapticManager.soft()
    }

    // MARK: - Breathing Cycle

    private func startBreathingCycle() {
        guard !reduceMotion else { return }
        breathPhase = .inhale
        cycleBreath()
    }

    private func cycleBreath() {
        guard isRunning, !reduceMotion else { return }
        // Each phase lasts 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            guard isRunning else { return }
            withAnimation(.easeInOut(duration: 0.5)) {
                breathPhase = breathPhase.next
            }
            cycleBreath()
        }
    }

    // MARK: - Local Notification for Background Completion

    private func scheduleCompletionNotification(secondsRemaining: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            let content = UNMutableNotificationContent()
            content.title = "NoBuy"
            content.body = "You beat the urge! 🎉 Congratulations."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(1, secondsRemaining),
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: Self.completionNotificationID,
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error {
                    AppLogger.notification.error("Failed to schedule urge completion notification: \(error.localizedDescription)")
                }
            }
        }
    }

    private func cancelCompletionNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.completionNotificationID])
    }
}

#Preview {
    UrgeSurfingView()
}
