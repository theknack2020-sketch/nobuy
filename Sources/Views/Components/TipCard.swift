import SwiftUI

struct TipCard: View {
    @State private var currentTip: TipEntry = TipEntry(text: "", icon: "lightbulb.fill", tint: .mandatoryAmber)
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct TipEntry {
        let text: String
        let icon: String
        let tint: Color
    }

    private let tips: [TipEntry] = [
        TipEntry(text: L10n.tip1, icon: "cart.badge.questionmark", tint: .mandatoryAmber),
        TipEntry(text: L10n.tip2, icon: "clock.fill", tint: .orange),
        TipEntry(text: L10n.tip3, icon: "list.clipboard.fill", tint: .noBuyGreen),
        TipEntry(text: L10n.tip4, icon: "face.smiling.inverse", tint: .spendRed),
        TipEntry(text: L10n.tip5, icon: "arrow.up.forward", tint: .noBuyGreen),
        TipEntry(text: L10n.tip6, icon: "leaf.fill", tint: .noBuyGreen),
        TipEntry(text: L10n.tip7, icon: "questionmark.bubble.fill", tint: .blue),
        TipEntry(text: L10n.tip8, icon: "figure.walk", tint: .orange),
        TipEntry(text: L10n.tip9, icon: "bell.slash.fill", tint: .spendRed),
        TipEntry(text: L10n.tip10, icon: "trophy.fill", tint: .mandatoryAmber),
        TipEntry(text: L10n.tip11, icon: "wind", tint: .blue),
        TipEntry(text: L10n.tip12, icon: "creditcard.trianglebadge.exclamationmark", tint: .spendRed),
        TipEntry(text: L10n.tip13, icon: "envelope.open.fill", tint: .orange),
        TipEntry(text: L10n.tip14, icon: "chart.line.uptrend.xyaxis", tint: .noBuyGreen),
        TipEntry(text: L10n.tip15, icon: "brain.head.profile", tint: .purple),
        TipEntry(text: L10n.tip16, icon: "lock.open.fill", tint: .blue),
        TipEntry(text: L10n.tip17, icon: "calendar.badge.clock", tint: .mandatoryAmber),
        TipEntry(text: L10n.tip18, icon: "heart.fill", tint: .pink),
        TipEntry(text: L10n.tip19, icon: "person.fill.checkmark", tint: .noBuyGreen),
        TipEntry(text: L10n.tip20, icon: "sparkles", tint: .orange),
    ]

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.md) {
            // Icon with gradient background circle
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [currentTip.tint.opacity(0.25), currentTip.tint.opacity(0.05)],
                            center: .center,
                            startRadius: 2,
                            endRadius: 20
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: currentTip.icon)
                    .font(.body)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [currentTip.tint, currentTip.tint.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: currentTip.tint.opacity(0.3), radius: 3, x: 0, y: 1)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("Daily Insight")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(currentTip.tint.opacity(0.8))
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(currentTip.text)
                    .font(.callout)
                    .foregroundStyle(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .fill(
                    LinearGradient(
                        colors: [currentTip.tint.opacity(0.08), currentTip.tint.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.md)
                        .stroke(currentTip.tint.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: currentTip.tint.opacity(0.08), radius: 4, x: 0, y: 2)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : (reduceMotion ? 0 : 8))
        .onAppear {
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
            currentTip = tips[dayOfYear % tips.count]
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.3)) {
                    appeared = true
                }
            }
        }
        .pressable()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily tip: \(currentTip.text)")
    }
}

#Preview {
    TipCard()
        .padding()
}
