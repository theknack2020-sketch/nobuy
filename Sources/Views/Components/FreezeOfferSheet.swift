import SwiftUI

struct FreezeOfferSheet: View {
    let streakCount: Int
    let freezesRemaining: Int
    let onUseFreeze: () -> Void
    let onDecline: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: DS.Spacing.xxl) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.noBuyGreen.opacity(0.25), .noBuyGreen.opacity(0.02)],
                            center: .center,
                            startRadius: 5,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "shield.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.noBuyGreen, .green.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolEffect(.pulse, value: reduceMotion ? false : appeared)
                    .shadow(color: .noBuyGreen.opacity(0.3), radius: 6, x: 0, y: 3)
                    .accessibilityHidden(true)
            }

            VStack(spacing: DS.Spacing.sm) {
                Text("Protect Your Streak")
                    .font(.system(size: 22, weight: .bold, design: .rounded))

                Text("Your \(streakCount)-day streak is about to break. Use a freeze to protect it.")
                    .font(.body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
            }

            // Freeze count indicator
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "shield.fill")
                    .foregroundStyle(.noBuyGreen)
                Text("You have \(freezesRemaining) freezes left")
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.vertical, DS.Spacing.md)
            .background(
                Capsule().fill(Color.noBuyGreenLight)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

            VStack(spacing: DS.Spacing.md) {
                // Use freeze
                Button {
                    HapticManager.success()
                    SoundManager.playIfEnabled(.freeze)
                    onUseFreeze()
                } label: {
                    HStack {
                        Image(systemName: "shield.checkered")
                            .font(.title3)
                        Text("Use Freeze")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
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
                .buttonStyle(.scale)
                .accessibilityLabel("Use streak freeze")
                .accessibilityHint("Double tap to protect your \(streakCount) day streak")
                .accessibilityIdentifier("use_freeze_button")

                // Decline
                Button {
                    HapticManager.warning()
                    SoundManager.playIfEnabled(.streakBreak)
                    onDecline()
                } label: {
                    Text("Skip, let the streak break")
                        .font(.subheadline)
                        .foregroundStyle(.spendRed)
                }
                .buttonStyle(.scale)
                .accessibilityLabel("Decline freeze, let streak break")
                .accessibilityHint("Double tap to skip using freeze")
            }
            .padding(.horizontal, DS.Spacing.xxl)
        }
        .padding(DS.Spacing.xxxl)
        .onAppear {
            HapticManager.warning()
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    appeared = true
                }
            }
        }
    }
}

#Preview {
    FreezeOfferSheet(
        streakCount: 14,
        freezesRemaining: 1,
        onUseFreeze: {},
        onDecline: {}
    )
}
