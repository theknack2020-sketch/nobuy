import SwiftUI

struct SummaryPill: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text("\(count)")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.textPrimary)
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : DS.Anim.normal, value: count)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .fill(color.opacity(0.1))
        )
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
