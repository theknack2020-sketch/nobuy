import SwiftUI

struct MilestoneModal: View {
    let streak: Int
    let achievement: Achievement?
    let onDismiss: () -> Void
    @State private var appear = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
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
                                colors: [milestoneColor.opacity(0.3), milestoneColor.opacity(0.05)],
                                center: .center,
                                startRadius: 10,
                                endRadius: 70
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(appear ? 1.0 : (reduceMotion ? 1.0 : 0.3))
                        .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.5), value: appear)

                    Image(systemName: achievement?.icon ?? milestoneIcon)
                        .font(Font.adaptiveDisplay(size: 56, isRegular: isRegular))
                        .foregroundStyle(milestoneColor)
                        .symbolEffect(.bounce, value: reduceMotion ? false : appear)
                        .shadow(color: milestoneColor.opacity(0.4), radius: 8, x: 0, y: 4)
                        .accessibilityHidden(true)
                }

                VStack(spacing: DS.Spacing.sm) {
                    Text(achievement?.title ?? milestoneTitle)
                        .font(Font.adaptiveDisplay(size: 28, weight: .bold, design: .rounded, isRegular: isRegular))
                        .multilineTextAlignment(.center)

                    Text(achievement?.description ?? milestoneDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.xxxl)
                }

                Text("\(streak)")
                    .font(Font.adaptiveDisplay(size: 64, weight: .black, design: .rounded, isRegular: isRegular))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [milestoneColor, milestoneColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .contentTransition(.numericText())
                    .shadow(color: milestoneColor.opacity(0.3), radius: 4, x: 0, y: 2)

                Text("day streak")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(2)

                Button {
                    HapticManager.tap()
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                .fill(
                                    LinearGradient(
                                        colors: [milestoneColor, milestoneColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: milestoneColor.opacity(0.35), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.scale)
                .padding(.horizontal, DS.Spacing.xxl)
                .accessibilityLabel("Continue")
                .accessibilityIdentifier("milestone_continue")
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
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Milestone reached: \(achievement?.title ?? milestoneTitle). \(streak) day streak.")
        }
        .onAppear {
            HapticManager.streakMilestone()
            SoundManager.playIfEnabled(.milestone)
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

    private var milestoneColor: Color {
        switch streak {
        case 1 ... 3: .noBuyGreen
        case 4 ... 7: .blue
        case 8 ... 14: .purple
        case 15 ... 30: .orange
        default: Color(red: 0.85, green: 0.65, blue: 0.13) // Gold
        }
    }

    private var milestoneIcon: String {
        switch streak {
        case 1: "star.fill"
        case 3: "flame.fill"
        case 7: "trophy.fill"
        case 14: "medal.fill"
        case 30: "crown.fill"
        case 60: "bolt.shield.fill"
        case 100: "star.circle.fill"
        default: "sparkles"
        }
    }

    private var milestoneTitle: String {
        switch streak {
        case 1: "First Step!"
        case 3: "3 Days Done!"
        case 7: "One Week!"
        case 14: "Two Weeks!"
        case 30: "One Month!"
        case 60: "60 Days!"
        case 100: "100 Days!"
        default: "\(streak) Days!"
        }
    }

    private var milestoneDescription: String {
        switch streak {
        case 1: "The journey has begun. Every long road starts with a single step."
        case 3: "A habit is forming. You're doing great!"
        case 7: "A full week! You've proven your willpower."
        case 14: "You stayed strong for two weeks. This is becoming a lifestyle."
        case 30: "30 days! You're a savings machine."
        default: "An incredible achievement! Keep going."
        }
    }
}
