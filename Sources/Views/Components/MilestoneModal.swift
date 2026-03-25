import SwiftUI

struct MilestoneModal: View {
    let streak: Int
    let achievement: Achievement?
    let onDismiss: () -> Void
    @State private var appear = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
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
                        .font(.system(size: 56))
                        .foregroundStyle(milestoneColor)
                        .symbolEffect(.bounce, value: reduceMotion ? false : appear)
                        .shadow(color: milestoneColor.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                
                VStack(spacing: DS.Spacing.sm) {
                    Text(achievement?.title ?? milestoneTitle)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                    
                    Text(achievement?.description ?? milestoneDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.xxxl)
                }
                
                Text("\(streak)")
                    .font(.system(size: 64, weight: .black, design: .rounded))
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
        case 1...3: return .noBuyGreen
        case 4...7: return .blue
        case 8...14: return .purple
        case 15...30: return .orange
        default: return Color(red: 0.85, green: 0.65, blue: 0.13) // Gold
        }
    }
    
    private var milestoneIcon: String {
        switch streak {
        case 1: return "star.fill"
        case 3: return "flame.fill"
        case 7: return "trophy.fill"
        case 14: return "medal.fill"
        case 30: return "crown.fill"
        case 60: return "bolt.shield.fill"
        case 100: return "star.circle.fill"
        default: return "sparkles"
        }
    }
    
    private var milestoneTitle: String {
        switch streak {
        case 1: return "First Step!"
        case 3: return "3 Days Done!"
        case 7: return "One Week!"
        case 14: return "Two Weeks!"
        case 30: return "One Month!"
        case 60: return "60 Days!"
        case 100: return "100 Days!"
        default: return "\(streak) Days!"
        }
    }
    
    private var milestoneDescription: String {
        switch streak {
        case 1: return "The journey has begun. Every long road starts with a single step."
        case 3: return "A habit is forming. You're doing great!"
        case 7: return "A full week! You've proven your willpower."
        case 14: return "You stayed strong for two weeks. This is becoming a lifestyle."
        case 30: return "30 days! You're a savings machine."
        default: return "An incredible achievement! Keep going."
        }
    }
}
