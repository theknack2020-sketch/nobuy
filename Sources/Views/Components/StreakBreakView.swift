import SwiftUI

struct StreakBreakView: View {
    let previousStreak: Int
    let longestStreak: Int
    let onDismiss: () -> Void
    @State private var appear = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var compassionateMessages: [String] {
        [
            "One day doesn't change everything. Tomorrow is a fresh start.",
            "You were strong for \(previousStreak) days. That's still an achievement.",
            "What matters isn't falling, it's getting back up. Tomorrow's with you.",
        ]
    }

    var body: some View {
        VStack(spacing: DS.Spacing.xxl) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.spendRed.opacity(0.15), .spendRed.opacity(0.02)],
                            center: .center,
                            startRadius: 5,
                            endRadius: 45
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "heart.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.spendRed.opacity(0.6))
                    .symbolEffect(.pulse, value: reduceMotion ? false : appear)
                    .shadow(color: .spendRed.opacity(0.2), radius: 6, x: 0, y: 3)
                    .accessibilityHidden(true)
            }

            Text("Streak ended")
                .font(.system(size: 22, weight: .bold, design: .rounded))

            Text(compassionateMessages.randomElement()!)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xxl)

            if previousStreak > 0 {
                HStack(spacing: DS.Spacing.xl) {
                    VStack {
                        Text("\(previousStreak)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.textSecondary)
                        Text("Last streak")
                            .font(.caption)
                            .foregroundStyle(.textTertiary)
                    }
                    .padding(DS.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .fill(Color.surfaceSecondary)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Last streak: \(previousStreak) days")

                    VStack {
                        Text("\(longestStreak)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.noBuyGreen)
                        Text("Best")
                            .font(.caption)
                            .foregroundStyle(.textTertiary)
                    }
                    .padding(DS.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .fill(Color.surfaceSecondary)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Best streak: \(longestStreak) days")
                }
                .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.7), value: appear)
            }

            Button {
                HapticManager.success()
                SoundManager.playIfEnabled(.success)
                onDismiss()
            } label: {
                Text("Start New Streak")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
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
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, DS.Spacing.xxl)
            .accessibilityLabel("Start new streak")
            .accessibilityHint("Double tap to begin a new no-spend streak")
            .accessibilityIdentifier("start_new_streak")
        }
        .padding(DS.Spacing.xxxl)
        .onAppear {
            HapticManager.streakBreak()
            SoundManager.playIfEnabled(.streakBreak)
            if reduceMotion {
                appear = true
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { appear = true }
            }
        }
    }
}
