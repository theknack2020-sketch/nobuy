import SwiftUI

struct SummaryPill: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .accessibilityHidden(true)

            Text("\(count)")
                .font(Font.adaptiveDisplay(size: 24, weight: .black, design: .rounded, isRegular: isRegular))
                .foregroundStyle(.textPrimary)
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : DS.Anim.normal, value: count)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.12), color.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.md)
                        .stroke(color.opacity(0.08), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        .scaleEffect(appeared ? 1.0 : (reduceMotion ? 1.0 : 0.8))
        .opacity(appeared ? 1.0 : 0)
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(DS.Anim.normal.delay(DS.Anim.stagger)) {
                    appeared = true
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(count)")
    }
}

#Preview {
    HStack {
        SummaryPill(icon: "checkmark.circle.fill", count: 12, label: "No-Spend", color: .noBuyGreen)
        SummaryPill(icon: "xmark.circle.fill", count: 5, label: "Spent", color: .spendRed)
        SummaryPill(icon: "questionmark.circle", count: 3, label: "Unrecorded", color: .gray)
    }
    .padding()
}
