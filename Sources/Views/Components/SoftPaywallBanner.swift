import SwiftUI

struct SoftPaywallBanner: View {
    let message: String
    let onUpgrade: () -> Void
    let onDismiss: () -> Void
    @State private var appear = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: "crown.fill")
                .foregroundStyle(
                    LinearGradient(
                        colors: [.mandatoryAmber, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .accessibilityHidden(true)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.textPrimary)

            Spacer()

            Button("Explore") {
                HapticManager.tap()
                SoundManager.playIfEnabled(.tap)
                onUpgrade()
            }
            .font(.subheadline.bold())
            .foregroundStyle(.noBuyGreen)
            .buttonStyle(.scale)
            .accessibilityLabel("Explore Pro features")
            .accessibilityHint("Double tap to view Pro upgrade")

            Button {
                HapticManager.tap()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { onDismiss() }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.scale)
            .accessibilityLabel("Dismiss banner")
            .accessibilityIdentifier("soft_paywall_dismiss")
        }
        .padding(DS.Spacing.lg)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .fill(
                    LinearGradient(
                        colors: [Color.noBuyGreenLight, Color.noBuyGreenLight.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : (reduceMotion ? 0 : 20))
        .onAppear {
            if reduceMotion {
                appear = true
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) { appear = true }
            }
        }
    }
}
