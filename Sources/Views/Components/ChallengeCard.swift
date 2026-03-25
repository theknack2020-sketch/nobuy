import SwiftUI

struct ChallengeCard: View {
    let daysCompleted: Int
    let totalDays: Int
    let daysRemaining: Int
    let progress: Double
    let isCompleted: Bool
    let onSetup: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var showCelebration = false

    /// Convenience initializer that counts actual no-buy days from records within the challenge date range.
    init(
        challengeStartDate: Date?,
        challengeDuration: Int,
        records: [DayRecord],
        onSetup: @escaping () -> Void
    ) {
        self.totalDays = challengeDuration
        self.onSetup = onSetup

        if let start = challengeStartDate, challengeDuration > 0 {
            let calendar = Calendar.current
            let endDate = calendar.date(byAdding: .day, value: challengeDuration, to: start) ?? start
            let noBuyCount = records.filter { record in
                let day = calendar.startOfDay(for: record.date)
                return day >= start && day < endDate && record.isNoBuyDay
            }.count
            self.daysCompleted = min(noBuyCount, challengeDuration)

            let elapsed = calendar.dateComponents([.day], from: start, to: .now).day ?? 0
            let isComplete = elapsed >= challengeDuration
            self.isCompleted = isComplete
            self.daysRemaining = isComplete ? 0 : max(challengeDuration - noBuyCount, 0)
            self.progress = challengeDuration > 0 ? Double(daysCompleted) / Double(challengeDuration) : 0
        } else {
            self.daysCompleted = 0
            self.daysRemaining = 0
            self.progress = 0
            self.isCompleted = false
        }
    }

    /// Direct initializer for previews and manual use.
    init(
        daysCompleted: Int,
        totalDays: Int,
        daysRemaining: Int,
        progress: Double,
        isCompleted: Bool,
        onSetup: @escaping () -> Void
    ) {
        self.daysCompleted = daysCompleted
        self.totalDays = totalDays
        self.daysRemaining = daysRemaining
        self.progress = progress
        self.isCompleted = isCompleted
        self.onSetup = onSetup
    }

    var body: some View {
        if totalDays > 0 {
            activeChallenge
        } else {
            startChallengeButton
        }
    }

    // MARK: - Active Challenge

    private var activeChallenge: some View {
        VStack(spacing: DS.Spacing.md) {
            HStack {
                Image(systemName: isCompleted ? "trophy.fill" : "flame.fill")
                    .foregroundStyle(isCompleted ? .mandatoryAmber : .noBuyGreen)
                    .symbolEffect(.bounce, value: appeared)
                Text("Challenge")
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(totalDays) days")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }

            // Progress ring + info
            HStack(spacing: DS.Spacing.xl) {
                // Circular progress ring
                ZStack {
                    Circle()
                        .stroke(Color.surfaceTertiary, lineWidth: 6)

                    Circle()
                        .trim(from: 0, to: appeared ? progress : 0)
                        .stroke(
                            isCompleted
                                ? LinearGradient(colors: [.mandatoryAmber, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [.noBuyGreen, .green.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(reduceMotion ? nil : .spring(response: 0.8, dampingFraction: 0.6), value: appeared)

                    VStack(spacing: 0) {
                        Text("\(daysCompleted)")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(isCompleted ? .mandatoryAmber : .noBuyGreen)
                        Text("/\(totalDays)")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.textTertiary)
                    }
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    if isCompleted {
                        Text("Challenge completed! 🎉")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.mandatoryAmber)
                    } else {
                        Text("\(daysRemaining) days left")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        // Percentage
                        Text("\(Int(progress * 100))% completed")
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                    }
                }

                Spacer()

                if isCompleted {
                    Button {
                        HapticManager.tap()
                        SoundManager.playIfEnabled(.tap)
                        onSetup()
                    } label: {
                        Text("New")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.noBuyGreen)
                            .padding(.horizontal, DS.Spacing.md)
                            .padding(.vertical, DS.Spacing.sm)
                            .background(
                                Capsule().fill(Color.noBuyGreenLight)
                            )
                    }
                    .buttonStyle(.scale)
                    .accessibilityLabel("Start new challenge")
                    .accessibilityHint("Double tap to set up a new challenge")
                }
            }
        }
        .padding(DS.Spacing.xl)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg)
                .fill(Color.surfaceSecondary)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
                    appeared = true
                }
            }
            if isCompleted {
                HapticManager.streakMilestone()
                SoundManager.playIfEnabled(.milestone)
            }
        }
        .pressable()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            isCompleted
                ? "Challenge completed. \(totalDays) days."
                : "Challenge: \(daysCompleted) / \(totalDays) days. \(daysRemaining) days remaining."
        )
    }

    // MARK: - Start Challenge Button

    private var startChallengeButton: some View {
        Button {
            HapticManager.tap()
            SoundManager.playIfEnabled(.tap)
            onSetup()
        } label: {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.noBuyGreen)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Start Challenge")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.textPrimary)
                    Text("Set yourself a goal")
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
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.scale)
        .accessibilityLabel("Start a no-spend challenge")
        .accessibilityHint("Double tap to set up a new challenge")
        .accessibilityIdentifier("start_challenge_button")
    }
}

#Preview {
    VStack(spacing: 16) {
        ChallengeCard(
            daysCompleted: 5,
            totalDays: 30,
            daysRemaining: 25,
            progress: 5.0 / 30.0,
            isCompleted: false,
            onSetup: {}
        )
        ChallengeCard(
            daysCompleted: 30,
            totalDays: 30,
            daysRemaining: 0,
            progress: 1.0,
            isCompleted: true,
            onSetup: {}
        )
        ChallengeCard(
            daysCompleted: 0,
            totalDays: 0,
            daysRemaining: 0,
            progress: 0,
            isCompleted: false,
            onSetup: {}
        )
    }
    .padding()
}
