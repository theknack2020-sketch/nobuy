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
            Color.surfaceScrim.opacity(appear ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: DS.Spacing.xxl) {
                ZStack {
                    Circle()
                        .fill(
                            milestoneColor.opacity(0.12)
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(appear ? 1.0 : (reduceMotion ? 1.0 : 0.3))
                        .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.5), value: appear)

                    Image(systemName: achievement?.icon ?? milestoneIcon)
                        .font(Font.adaptiveDisplay(size: 56, isRegular: isRegular))
                        .foregroundStyle(milestoneColor)
                        .symbolEffect(.bounce, value: reduceMotion ? false : appear)

                        .accessibilityHidden(true)
                }

                VStack(spacing: DS.Spacing.sm) {
                    Text(achievement?.title ?? milestoneTitle)
                        .font(Font.adaptiveDisplay(size: 28, weight: .semibold, isRegular: isRegular))
                        .multilineTextAlignment(.center)

                    Text(achievement?.description ?? milestoneDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.xxxl)
                }

                Text("\(streak)")
                    .font(Font.adaptiveDisplay(size: 64, weight: .semibold, isRegular: isRegular))
                    .foregroundStyle(
                        milestoneColor
                    )
                    .contentTransition(.numericText())

                Text("day streak")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(2)
                    .opacity(appear ? 1 : 0)
                    .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger * 2), value: appear)

                Button {
                    HapticManager.tap()
                    dismiss()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(Color.inkOnAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                .fill(
                                    milestoneColor
                                )
                        )

                }
                .buttonStyle(.scale)
                .padding(.horizontal, DS.Spacing.xxl)
                .accessibilityLabel("Continue")
                .accessibilityIdentifier("milestone_continue")
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
        case 1 ... 3: .accentKept
        case 4 ... 7: .stateWait
        case 8 ... 14: .stateWait
        case 15 ... 30: .accentSpentMark
        default: Color.accentKept // one accent; milestones do not get their own hue
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
