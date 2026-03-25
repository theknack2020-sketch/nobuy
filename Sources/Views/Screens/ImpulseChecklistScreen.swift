import SwiftUI

// MARK: - Impulse Checklist Screen
// Before-you-buy questionnaire — 5 questions, one at a time.
// Accessible from HomeScreen ("I want to buy but...") and SpendOptionsSheet.

struct ImpulseChecklistScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var currentIndex = 0
    @State private var answers: [Bool?] = Array(repeating: nil, count: 5)
    @State private var phase: Phase = .questions
    @State private var showConfetti = false
    @State private var showWaitingListOffer = false
    @State private var waitingItemName = ""
    @State private var waitingItemCost = ""
    @State private var waitingReminderHours = 24

    /// Callback when the user completes the checklist and decides NOT to buy
    var onDecidedNotToBuy: (() -> Void)?

    enum Phase {
        case questions
        case earlyExit   // Answered in a way that clearly says "don't buy"
        case summary
    }

    // MARK: - Question Model

    private struct Question {
        let icon: String
        let text: String
        /// If the user picks this answer, trigger an early "don't buy" exit.
        /// `nil` means no early exit for either answer.
        let earlyExitAnswer: Bool?
    }

    private let questions: [Question] = [
        Question(
            icon: "questionmark.circle.fill",
            text: "Do I really need this?",
            earlyExitAnswer: false  // "No" → early exit
        ),
        Question(
            icon: "clock.fill",
            text: "Can I wait 24 hours?",
            earlyExitAnswer: true   // "Yes" → early exit
        ),
        Question(
            icon: "banknote.fill",
            text: "Does this fit my budget?",
            earlyExitAnswer: nil
        ),
        Question(
            icon: "calendar.badge.clock",
            text: "Will I still want this in a week?",
            earlyExitAnswer: nil
        ),
        Question(
            icon: "arrow.triangle.branch",
            text: "What else could I spend this money on?",
            earlyExitAnswer: nil
        ),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePrimary.ignoresSafeArea()

                switch phase {
                case .questions:
                    questionView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .earlyExit:
                    earlyExitView
                        .transition(.scale.combined(with: .opacity))
                case .summary:
                    summaryView
                        .transition(.scale.combined(with: .opacity))
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
                        dismiss()
                    }
                    .accessibilityIdentifier("impulse_close")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showWaitingListOffer) {
            waitingListOfferSheet
        }
    }

    // MARK: - Question View

    private var questionView: some View {
        let question = questions[currentIndex]

        return VStack(spacing: DS.Spacing.xxxl) {
            Spacer()

            // Progress
            progressDots

            // Icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.noBuyGreen.opacity(0.2), .noBuyGreen.opacity(0.02)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: question.icon)
                    .font(.system(size: 52))
                    .foregroundStyle(.noBuyGreen)
                    .shadow(color: .noBuyGreen.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .id("icon-\(currentIndex)")

            // Question text
            Text(question.text)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xxl)
                .id("text-\(currentIndex)")

            Spacer()

            // Answer buttons
            HStack(spacing: DS.Spacing.lg) {
                answerButton(
                    label: "Yes",
                    icon: "checkmark",
                    color: .noBuyGreen,
                    isYes: true
                )

                answerButton(
                    label: "No",
                    icon: "xmark",
                    color: .spendRed,
                    isYes: false
                )
            }
            .padding(.horizontal, DS.Spacing.xxl)
            .padding(.bottom, DS.Spacing.xxxl)
        }
    }

    private func answerButton(label: String, icon: String, color: Color, isYes: Bool) -> some View {
        Button {
            answer(isYes)
        } label: {
            VStack(spacing: DS.Spacing.sm) {
                Image(systemName: icon)
                    .font(.title2.bold())
                Text(label)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.xl)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.scale)
        .accessibilityLabel("\(label)")
        .accessibilityHint("Double tap to answer \(label.lowercased()) to the question")
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: DS.Spacing.sm) {
            ForEach(0..<questions.count, id: \.self) { index in
                Circle()
                    .fill(dotColor(for: index))
                    .frame(width: index == currentIndex ? 12 : 8,
                           height: index == currentIndex ? 12 : 8)
                    .shadow(color: index == currentIndex ? .noBuyGreen.opacity(0.3) : .clear, radius: 3, x: 0, y: 1)
                    .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Question \(currentIndex + 1) of \(questions.count)")
    }

    private func dotColor(for index: Int) -> Color {
        if index < currentIndex {
            return .noBuyGreen
        } else if index == currentIndex {
            return .noBuyGreen
        } else {
            return .textTertiary.opacity(0.3)
        }
    }

    // MARK: - Answer Logic

    private func answer(_ isYes: Bool) {
        HapticManager.tap()
        SoundManager.playIfEnabled(.tap)
        answers[currentIndex] = isYes

        let question = questions[currentIndex]

        // Check for early exit
        if let earlyAnswer = question.earlyExitAnswer, isYes == earlyAnswer {
            withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.7)) {
                phase = .earlyExit
                showConfetti = true
            }
            HapticManager.celebration()
            SoundManager.playIfEnabled(.celebration)
            trackCompletion(didBuy: false)
            scheduleConfettiDismiss()
            return
        }

        // Move to next question or summary
        if currentIndex < questions.count - 1 {
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7)) {
                currentIndex += 1
            }
        } else {
            withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.7)) {
                phase = .summary
                if shouldNotBuy {
                    showConfetti = true
                    HapticManager.celebration()
                    SoundManager.playIfEnabled(.celebration)
                    scheduleConfettiDismiss()
                } else {
                    HapticManager.warning()
                }
            }
            trackCompletion(didBuy: !shouldNotBuy)
        }
    }

    // MARK: - Early Exit View

    private var earlyExitView: some View {
        VStack(spacing: DS.Spacing.xxxl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.noBuyGreen.opacity(0.2), .noBuyGreen.opacity(0.02)],
                            center: .center,
                            startRadius: 15,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.noBuyGreen)
                    .shadow(color: .noBuyGreen.opacity(0.3), radius: 8, x: 0, y: 4)
            }

            VStack(spacing: DS.Spacing.md) {
                Text("Great! Consider holding off on this purchase.")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xxl)
                    .accessibilityAddTraits(.isHeader)

                Text("This feeling is temporary. Wait a while and think again.")
                    .font(.body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xxxl)
            }

            Spacer()

            VStack(spacing: DS.Spacing.md) {
                // Waiting list offer
                Button {
                    HapticManager.tap()
                    SoundManager.playIfEnabled(.tap)
                    showWaitingListOffer = true
                } label: {
                    HStack(spacing: DS.Spacing.sm) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.title3)
                        Text("Add to Waiting List")
                            .fontWeight(.semibold)
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
                .accessibilityLabel("Add to waiting list")
                .accessibilityHint("Double tap to save this item for later")

                Button {
                    HapticManager.success()
                    SoundManager.playIfEnabled(.success)
                    onDecidedNotToBuy?()
                    dismiss()
                } label: {
                    Text("You strengthened your willpower! 💪")
                        .font(.subheadline)
                        .foregroundStyle(.noBuyGreen)
                }

                Button {
                    HapticManager.tap()
                    // Continue with remaining questions
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7)) {
                        showConfetti = false
                        phase = .questions
                        if currentIndex < questions.count - 1 {
                            currentIndex += 1
                        }
                    }
                } label: {
                    Text("Continue anyway")
                        .font(.subheadline)
                        .foregroundStyle(.textTertiary)
                }
            }
            .padding(.horizontal, DS.Spacing.xxl)
            .padding(.bottom, DS.Spacing.xxxl)
        }
    }

    // MARK: - Summary View

    private var summaryView: some View {
        let buyCount = buyScore
        let waitCount = questions.count - buyCount

        return VStack(spacing: DS.Spacing.xxxl) {
            Spacer()

            // Result icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [(shouldNotBuy ? Color.noBuyGreen : Color.mandatoryAmber).opacity(0.2), (shouldNotBuy ? Color.noBuyGreen : Color.mandatoryAmber).opacity(0.02)],
                            center: .center,
                            startRadius: 15,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: shouldNotBuy ? "trophy.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(shouldNotBuy ? .noBuyGreen : .mandatoryAmber)
                    .shadow(color: (shouldNotBuy ? Color.noBuyGreen : .mandatoryAmber).opacity(0.3), radius: 8, x: 0, y: 4)
            }

            // Result text
            VStack(spacing: DS.Spacing.md) {
                Text(shouldNotBuy
                     ? "You strengthened your willpower!"
                     : "You're still not sure")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                // Score breakdown
                HStack(spacing: DS.Spacing.xxl) {
                    scorePill(
                        count: buyCount,
                        total: questions.count,
                        label: "Buy",
                        color: .spendRed
                    )
                    scorePill(
                        count: waitCount,
                        total: questions.count,
                        label: "Wait",
                        color: .noBuyGreen
                    )
                }
            }

            Spacer()

            // Action buttons
            VStack(spacing: DS.Spacing.md) {
                if shouldNotBuy {
                    // Waiting list offer — primary action
                    Button {
                        HapticManager.tap()
                        SoundManager.playIfEnabled(.tap)
                        showWaitingListOffer = true
                    } label: {
                        HStack(spacing: DS.Spacing.sm) {
                            Image(systemName: "clock.badge.questionmark")
                                .font(.title3)
                            Text("Add to Waiting List")
                                .fontWeight(.semibold)
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

                    Button {
                        HapticManager.success()
                        SoundManager.playIfEnabled(.success)
                        onDecidedNotToBuy?()
                        dismiss()
                    } label: {
                        Text("Great decision! 🎉")
                            .font(.subheadline)
                            .foregroundStyle(.noBuyGreen)
                    }
                } else {
                    // Not clearly "don't buy" but offer waiting list on wait action
                    Button {
                        HapticManager.tap()
                        SoundManager.playIfEnabled(.tap)
                        showWaitingListOffer = true
                    } label: {
                        HStack(spacing: DS.Spacing.sm) {
                            Image(systemName: "clock.badge.questionmark")
                                .font(.title3)
                            Text("Wait & Add to List")
                                .fontWeight(.semibold)
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

                    Button {
                        HapticManager.tap()
                        dismiss()
                    } label: {
                        Text("Buy anyway")
                            .font(.subheadline)
                            .foregroundStyle(.textTertiary)
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.xxl)
            .padding(.bottom, DS.Spacing.xxxl)
        }
    }

    private func scorePill(count: Int, total: Int, label: String, color: Color) -> some View {
        VStack(spacing: DS.Spacing.xs) {
            Text("\(count)/\(total)")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.textSecondary)
        }
        .frame(width: 80)
        .padding(.vertical, DS.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .fill(color.opacity(0.1))
        )
        .shadow(color: color.opacity(0.12), radius: 4, x: 0, y: 2)
        .pressable()
    }

    // MARK: - Scoring

    /// How many answers point toward "buy".
    /// Q1 "Yes" (need it) → buy, Q2 "No" (can't wait) → buy,
    /// Q3 "Yes" (fits budget) → buy, Q4 "Yes" (still want) → buy,
    /// Q5 "No" (nothing else) → buy
    private var buyScore: Int {
        var score = 0
        if answers[0] == true  { score += 1 } // Yes I need it
        if answers[1] == false { score += 1 } // No I can't wait
        if answers[2] == true  { score += 1 } // Yes fits budget
        if answers[3] == true  { score += 1 } // Yes still want it
        if answers[4] == false { score += 1 } // No nothing else
        return score
    }

    private var shouldNotBuy: Bool {
        buyScore < 3
    }

    // MARK: - Tracking

    private func trackCompletion(didBuy: Bool) {
        let key = "impulseChecklistCompletions"
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + 1, forKey: key)

        if !didBuy {
            let savedKey = "impulseChecklistSaved"
            let saved = UserDefaults.standard.integer(forKey: savedKey)
            UserDefaults.standard.set(saved + 1, forKey: savedKey)
            SoundManager.playIfEnabled(.success)
        }
    }

    // MARK: - Waiting List Offer Sheet

    private var waitingListOfferSheet: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.xxl) {
                Spacer().frame(height: DS.Spacing.md)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.noBuyGreen.opacity(0.2), .noBuyGreen.opacity(0.02)],
                                center: .center,
                                startRadius: 5,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 36))
                        .foregroundStyle(.noBuyGreen)
                }

                Text("Set a reminder to prevent impulse purchases")
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xxl)

                VStack(spacing: DS.Spacing.lg) {
                    TextField(
                        "What do you want to buy?",
                        text: $waitingItemName
                    )
                    .font(.body)
                    .padding(DS.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .fill(Color.surfaceSecondary)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 2)

                    TextField(
                        "Estimated price (optional)",
                        text: $waitingItemCost
                    )
                    .font(.body)
                    .keyboardType(.decimalPad)
                    .padding(DS.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .fill(Color.surfaceSecondary)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 2)

                    // Reminder duration picker
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        Text("When should we remind you?")
                            .font(.subheadline)
                            .foregroundStyle(.textSecondary)

                        HStack(spacing: DS.Spacing.md) {
                            ForEach([24, 48, 72], id: \.self) { hours in
                                Button {
                                    HapticManager.tap()
                                    waitingReminderHours = hours
                                } label: {
                                    Text(reminderLabel(for: hours))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(waitingReminderHours == hours ? .white : .textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DS.Spacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: DS.Radius.md)
                                            .fill(waitingReminderHours == hours
                                                ? AnyShapeStyle(LinearGradient(colors: [.noBuyGreen, .noBuyGreen.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                                                : AnyShapeStyle(Color.surfaceSecondary))
                                    )
                                    .shadow(color: waitingReminderHours == hours ? .noBuyGreen.opacity(0.2) : .black.opacity(0.04), radius: 4, x: 0, y: 2)
                                }
                                .buttonStyle(.scale)
                                .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: waitingReminderHours)
                            }
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.xxl)

                Spacer()

                Button {
                    saveToWaitingList()
                } label: {
                    Text("Add to Waiting List")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.lg)
                                .fill(waitingItemName.trimmingCharacters(in: .whitespaces).isEmpty
                                      ? AnyShapeStyle(Color.noBuyGreen.opacity(0.4))
                                      : AnyShapeStyle(LinearGradient(colors: [.noBuyGreen, .noBuyGreen.opacity(0.8)], startPoint: .leading, endPoint: .trailing)))
                        )
                        .shadow(color: waitingItemName.trimmingCharacters(in: .whitespaces).isEmpty ? .clear : .noBuyGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.scale)
                .disabled(waitingItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, DS.Spacing.xxl)
                .padding(.bottom, DS.Spacing.xxxl)
            }
            .background(Color.surfacePrimary)
            .navigationTitle("Waiting List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.tap()
                        showWaitingListOffer = false
                    }
                    .accessibilityIdentifier("waiting_list_cancel")
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func saveToWaitingList() {
        let name = waitingItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let cost = Double(waitingItemCost.replacingOccurrences(of: ",", with: "."))
        let item = WaitingItem(name: name, estimatedCost: cost, reminderHours: waitingReminderHours)
        WaitingListManager.shared.addItem(item)

        HapticManager.save()
        SoundManager.playIfEnabled(.save)

        waitingItemName = ""
        waitingItemCost = ""
        waitingReminderHours = 24
        showWaitingListOffer = false

        onDecidedNotToBuy?()
        dismiss()
    }

    private func reminderLabel(for hours: Int) -> String {
        switch hours {
        case 24: return "24 hours"
        case 48: return "48 hours"
        case 72: return "72 hours"
        default: return "\(hours) hours"
        }
    }

    private func scheduleConfettiDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showConfetti = false
        }
    }
}

#Preview {
    ImpulseChecklistScreen()
}
