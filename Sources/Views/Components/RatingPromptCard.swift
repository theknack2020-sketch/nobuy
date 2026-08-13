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
                        .accentKept.opacity(0.12)
                    )
                    .frame(width: 88, height: 88)

                Image(systemName: "heart.fill")
                    .font(Font.adaptiveDisplay(size: 40, isRegular: isRegular))
                    .foregroundStyle(
                        .accentKept
                    )
                    .symbolEffect(.pulse, value: reduceMotion ? false : appeared)
                    .accessibilityHidden(true)
            }
            .scaleEffect(appeared ? 1.0 : (reduceMotion ? 1.0 : 0.6))
            .opacity(appeared ? 1 : 0)
            .animation(reduceMotion ? nil : DS.Anim.normal, value: appeared)

            VStack(spacing: DS.Spacing.sm) {
                Text("Enjoying NoBuy?")
                    .font(Font.adaptiveDisplay(size: 22, weight: .semibold, isRegular: isRegular))

                Text("\(streak) days without impulse buys — nice work!")
                    .font(.body)
                    .foregroundStyle(.inkSecondary)
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
                        Image(systemName: "star")
                            .font(.title3)
                            .accessibilityHidden(true)
                        Text("Love it!")
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
                        .foregroundStyle(.inkSecondary)
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
