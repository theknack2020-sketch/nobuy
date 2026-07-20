import StoreKit
import SwiftUI

/// The honest review pre-prompt, shown as a small sheet after a milestone
/// celebration. "Love it!" opens Apple's native rating prompt; "Could be
/// better" routes to private feedback in Mail. Dismissing without choosing is
/// fine — the cooldown was already recorded when the card was armed.
struct RatingPromptCard: View {
    let streak: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var appeared = false

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.noBuyGreen.opacity(0.25), .noBuyGreen.opacity(0.02)],
                            center: .center,
                            startRadius: 5,
                            endRadius: 44
                        )
                    )
                    .frame(width: 88, height: 88)

                Image(systemName: "heart.fill")
                    .font(Font.adaptiveDisplay(size: 40, isRegular: isRegular))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.noBuyGreen, .green.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolEffect(.pulse, value: reduceMotion ? false : appeared)
                    .accessibilityHidden(true)
            }
            .scaleEffect(appeared ? 1.0 : (reduceMotion ? 1.0 : 0.6))
            .opacity(appeared ? 1 : 0)
            .animation(reduceMotion ? nil : DS.Anim.normal, value: appeared)

            VStack(spacing: DS.Spacing.sm) {
                Text("Enjoying NoBuy?")
                    .font(Font.adaptiveDisplay(size: 22, weight: .bold, design: .rounded, isRegular: isRegular))

                Text("\(streak) days without impulse buys — nice work!")
                    .font(.body)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .animation(reduceMotion ? nil : DS.Anim.normal.delay(DS.Anim.stagger), value: appeared)

            VStack(spacing: DS.Spacing.md) {
                Button {
                    HapticManager.success()
                    RatingPrompt.shared.lovedIt(requestReview: requestReview)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.title3)
                            .accessibilityHidden(true)
                        Text("Love it!")
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
                .accessibilityLabel("Love it, rate NoBuy")
                .accessibilityHint("Double tap to rate NoBuy on the App Store")
                .accessibilityIdentifier("rating_prompt_love_it")

                Button {
                    HapticManager.tap()
                    RatingPrompt.shared.notForMe()
                    dismiss()
                } label: {
                    Text("Could be better")
                        .font(.subheadline)
                        .foregroundStyle(.textSecondary)
                }
                .buttonStyle(.scale)
                .accessibilityLabel("Could be better, send private feedback")
                .accessibilityHint("Double tap to email us your feedback")
                .accessibilityIdentifier("rating_prompt_feedback")
            }
            .padding(.horizontal, DS.Spacing.xxl)
        }
        .padding(.vertical, DS.Spacing.xxl)
        .accessibilityIdentifier("rating_prompt_card")
        .onAppear {
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
    RatingPromptCard(streak: 7)
}
