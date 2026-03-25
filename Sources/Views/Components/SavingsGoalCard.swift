import SwiftUI

struct SavingsGoalCard: View {
    let goalLabel: String
    let goalIcon: String
    let estimatedSavings: String
    let noBuyDays: Int
    let dailyEstimate: Double

    /// Optional target amount for circular progress
    var targetAmount: Double = 0

    @State private var appeared = false
    @State private var progressAnimationValue: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var currentSavings: Double {
        Double(noBuyDays) * dailyEstimate
    }

    private var progressFraction: Double {
        guard targetAmount > 0, dailyEstimate > 0 else { return 0 }
        return min(currentSavings / targetAmount, 1.0)
    }

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            HStack {
                Image(systemName: goalIcon)
                    .foregroundStyle(.noBuyGreen)
                Text("Savings Goal")
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }

            HStack(spacing: DS.Spacing.lg) {
                // Circular progress ring (or static badge when no target)
                ZStack {
                    if targetAmount > 0 && dailyEstimate > 0 {
                        // Background track
                        Circle()
                            .stroke(Color.noBuyGreenLight, lineWidth: 6)
                            .frame(width: 56, height: 56)

                        // Progress ring
                        Circle()
                            .trim(from: 0, to: progressAnimationValue)
                            .stroke(
                                Color.noBuyGreen,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 56, height: 56)
                            .rotationEffect(.degrees(-90))

                        // Percentage or icon inside
                        Text("\(Int(progressAnimationValue * 100))%")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.noBuyGreen)
                            .contentTransition(.numericText())
                    } else {
                        Circle()
                            .fill(Color.noBuyGreenLight)
                            .frame(width: 56, height: 56)
                        Image(systemName: goalIcon)
                            .font(.system(size: 22))
                            .foregroundStyle(.noBuyGreen)
                    }
                }
                .accessibilityLabel(targetAmount > 0 ? "\(Int(progressFraction * 100)) percent progress toward savings goal" : "Savings goal icon")

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text(goalLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if dailyEstimate > 0 {
                        HStack(spacing: DS.Spacing.xs) {
                            Text("Estimated savings:")
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                            Text(estimatedSavings)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.noBuyGreen)
                                .contentTransition(.numericText())
                        }

                        if targetAmount > 0 {
                            Text("\(formattedAmount(currentSavings)) of \(formattedAmount(targetAmount))")
                                .font(.caption2)
                                .foregroundStyle(.textTertiary)
                        }
                    }
                }

                Spacer()

                if dailyEstimate > 0 {
                    VStack(spacing: 2) {
                        Text("\(noBuyDays)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.noBuyGreen)
                            .contentTransition(.numericText())
                        Text("days")
                            .font(.caption2)
                            .foregroundStyle(.textTertiary)
                    }
                }
            }

            // Progress bar (days in current month)
            if dailyEstimate > 0 {
                let daysInMonth = Double(Calendar.current.range(of: .day, in: .month, for: .now)?.count ?? 30)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.surfaceTertiary)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.noBuyGreen)
                            .frame(
                                width: geo.size.width * min(Double(noBuyDays) / daysInMonth, 1.0),
                                height: 6
                            )
                            .animation(reduceMotion ? nil : .spring(duration: 0.5), value: noBuyDays)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(DS.Spacing.xl)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg)
                .fill(Color.surfaceSecondary)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : (reduceMotion ? 0 : 10))
        .onAppear {
            if reduceMotion {
                appeared = true
                progressAnimationValue = progressFraction
            } else {
                withAnimation(DS.Anim.normal.delay(0.4)) {
                    appeared = true
                }
                withAnimation(DS.Anim.slow.delay(0.6)) {
                    progressAnimationValue = progressFraction
                }
            }
        }
        .onChange(of: noBuyDays) {
            withAnimation(reduceMotion ? nil : DS.Anim.normal) {
                progressAnimationValue = progressFraction
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Savings Goal: \(goalLabel). \(dailyEstimate > 0 ? "Estimated savings: \(estimatedSavings)." : "") \(targetAmount > 0 ? "\(Int(progressFraction * 100)) percent complete." : "")")
    }

    private func formattedAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(Int(amount))"
    }
}

#Preview {
    VStack(spacing: 16) {
        SavingsGoalCard(
            goalLabel: "Vacation Fund",
            goalIcon: "airplane",
            estimatedSavings: "$1,500",
            noBuyDays: 15,
            dailyEstimate: 100,
            targetAmount: 5000
        )
        SavingsGoalCard(
            goalLabel: "Emergency Fund",
            goalIcon: "shield.fill",
            estimatedSavings: "$3,000",
            noBuyDays: 30,
            dailyEstimate: 100,
            targetAmount: 3000
        )
        SavingsGoalCard(
            goalLabel: "Just Discipline",
            goalIcon: "brain.head.profile",
            estimatedSavings: "$0",
            noBuyDays: 10,
            dailyEstimate: 0
        )
    }
    .padding()
}
