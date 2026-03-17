import SwiftUI

struct SummaryPill: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text("\(count)")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.textPrimary)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    HStack {
        SummaryPill(icon: "checkmark.circle.fill", count: 12, label: "Harcamasız", color: .noBuyGreen)
        SummaryPill(icon: "xmark.circle.fill", count: 5, label: "Harcamalı", color: .spendRed)
        SummaryPill(icon: "questionmark.circle", count: 3, label: "Kayıtsız", color: .gray)
    }
    .padding()
}
