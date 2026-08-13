import SwiftUI

struct ChallengeCelebrationModal: View {
    let totalDays: Int
    let onDismiss: () -> Void

    @State private var appear = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    private var celebrationMessage: String {
        switch totalDays {
        case ...7: "A solid week of discipline! You proved you can do it."
        case ...14: "Two weeks of willpower! You're building a real habit."
        case ...30: "A full month! Your self-control is inspiring."
        case ...60: "60 days of saying no. You're in the top 1% of savers."
        case ...100: "100 days! You've mastered the art of mindful spending."
        default: "You showed incredible willpower and commitment."
        }
    }

    var body: some View {
        ZStack {
            Color.surfaceScrim.opacity(appear ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: DS.Spacing.xxl) {
                ZStack {
                    Circle()
                        .fill(
                            .stateWait.opacity(0.12)
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(appear ? 1.0 : (reduceMotion ? 1.0 : 0.3))
                        .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.5), value: appear)

                    Image(systemName: "trophy.fill")
                        .font(Font.adaptiveDisplay(size: 56, isRegular: isRegular))
                        .accessibilityHidden(true)
                        .foregroundStyle(
                            .stateWait
                        )
                        .symbolEffect(.bounce, value: reduceMotion ? false : appear)

                }

                VStack(spacing: DS.Spacing.sm) {
                    Text("Challenge Completed!")
                        .font(Font.adaptiveDisplay(size: 28, weight: .semibold, isRegular: isRegular))
                        .multilineTextAlignment(.center)

                    Text(celebrationMessage)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.xl)
                }

                // Big number display
                VStack(spacing: DS.Spacing.xs) {
                    Text("\(totalDays)")
                        .font(Font.adaptiveDisplay(size: 64, weight: .semibold, isRegular: isRegular))
                        .foregroundStyle(
                            .stateWait
                        )
                        .contentTransition(.numericText())

                    Text("day challenge")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(2)
                }
                .opacity(appear ? 1 : 0)
                .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 2), value: appear)

                Button {
                    HapticManager.tap()
                    SoundManager.playIfEnabled(.tap)
                    dismiss()
                } label: {
                    Text("Well done")
                        .font(.headline)
                        .foregroundStyle(Color.inkOnAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                .fill(
                                    .stateWait
                                )
                        )

                }
                .buttonStyle(.scale)
                .padding(.horizontal, DS.Spacing.xxl)
            }
            .padding(DS.Spacing.xxxl)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.xl)
                    .fill(Color.surfaceField)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.xl)
                            .fill(DS.Gradient.card)
                    )

            )
            .padding(.horizontal, DS.Spacing.xxl)
            .scaleEffect(appear ? 1.0 : (reduceMotion ? 1.0 : 0.8))
            .opacity(appear ? 1.0 : 0)
        }
        .onAppear {
            HapticManager.celebration()
            SoundManager.playIfEnabled(.celebration)
            if reduceMotion {
                appear = true
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) { appear = true }
            }
        }
    }

    private func dismiss() {
        if reduceMotion {
            appear = false
            onDismiss()
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { appear = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onDismiss() }
        }
    }
}

#Preview {
    ChallengeCelebrationModal(totalDays: 30) {}
}
