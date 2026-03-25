import SwiftUI

struct ChallengeCelebrationModal: View {
    let totalDays: Int
    let onDismiss: () -> Void

    @State private var appear = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var celebrationMessage: String {
        switch totalDays {
        case ...7: return "A solid week of discipline! You proved you can do it."
        case ...14: return "Two weeks of willpower! You're building a real habit."
        case ...30: return "A full month! Your self-control is inspiring."
        case ...60: return "60 days of saying no. You're in the top 1% of savers."
        case ...100: return "100 days! You've mastered the art of mindful spending."
        default: return "You showed incredible willpower and commitment."
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(appear ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: DS.Spacing.xxl) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.mandatoryAmber.opacity(0.3), .mandatoryAmber.opacity(0.05)],
                                center: .center,
                                startRadius: 10,
                                endRadius: 70
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(appear ? 1.0 : (reduceMotion ? 1.0 : 0.3))
                        .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.5), value: appear)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.mandatoryAmber, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce, value: reduceMotion ? false : appear)
                        .shadow(color: .mandatoryAmber.opacity(0.4), radius: 8, x: 0, y: 4)
                }

                VStack(spacing: DS.Spacing.sm) {
                    Text("Challenge Completed!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
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
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.mandatoryAmber, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .contentTransition(.numericText())
                        .shadow(color: .mandatoryAmber.opacity(0.3), radius: 4, x: 0, y: 2)

                    Text("day challenge")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(2)
                }

                Button {
                    HapticManager.tap()
                    SoundManager.playIfEnabled(.tap)
                    dismiss()
                } label: {
                    Text("Awesome! 🎯")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                .fill(
                                    LinearGradient(
                                        colors: [.mandatoryAmber, .orange.opacity(0.85)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: .mandatoryAmber.opacity(0.35), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.scale)
                .padding(.horizontal, DS.Spacing.xxl)
            }
            .padding(DS.Spacing.xxxl)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.xl)
                    .fill(Color.surfacePrimary)
                    .shadow(color: .black.opacity(0.15), radius: 30, y: 10)
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
