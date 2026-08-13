import SwiftUI

struct FreezeOfferSheet: View {
    let streakCount: Int
    let freezesRemaining: Int
    let onUseFreeze: () -> Void
    let onDecline: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        VStack(spacing: DS.Spacing.xxl) {
            ZStack {
                Circle()
                    .fill(
                        .accentKept.opacity(0.12)
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "shield")
                    .font(Font.adaptiveDisplay(size: 48, isRegular: isRegular))
                    .foregroundStyle(
                        .accentKept
                    )
                    .symbolEffect(.pulse, value: reduceMotion ? false : appeared)

                    .accessibilityHidden(true)
            }
            .scaleEffect(appeared ? 1.0 : (reduceMotion ? 1.0 : 0.5))
            .opacity(appeared ? 1 : 0)
            .animation(reduceMotion ? nil : DS.Anim.normal, value: appeared)

            VStack(spacing: DS.Spacing.sm) {
                Text("Protect Your Streak")
                    .font(Font.adaptiveDisplay(size: 22, weight: .semibold, isRegular: isRegular))

                Text("Your \(streakCount)-day streak is about to break. Use a freeze to protect it.")
                    .font(.body)
                    .foregroundStyle(.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger), value: appeared)

            // Freeze count indicator
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "shield")
                    .foregroundStyle(.accentKept)
                Text("You have \(freezesRemaining) freezes left")
                    .font(.subheadline)
                    .foregroundStyle(.inkSecondary)
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.vertical, DS.Spacing.md)
            .background(
                Capsule().fill(Color.accentKeptWash)
            )

            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 2), value: appeared)

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
                            .accessibilityHidden(true)
                        Text("Use Freeze")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(Color.inkOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .fill(
                                .accentKept
                            )
                    )

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
                        .foregroundStyle(.accentSpentText)
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
