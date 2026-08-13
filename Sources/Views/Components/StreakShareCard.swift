import SwiftUI

// MARK: - Streak share cards
//
// Moved out of HomeScreen at the v2.0.0 redesign: a card that is rendered to an image and
// handed to the share sheet is a component, not a screen, and keeping it inside Today made
// that file 1300 lines of two unrelated jobs.
//
// The v1 cards painted a streak-tiered gradient (rainbow at 100, gold at 30, green below).
// Both token laws killed it: gradients may not decorate, and an accent may never encode a
// CATEGORY — a colour that changes with the count means the same ink says different things on
// different days. The card is now the dial's own surface, and the number is the only thing
// that grows.

struct StreakShareCard: View {
    let streakInfo: StreakInfo
    var savingsGoal: String = ""
    var firstNoBuyDate: Date?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    private var cardSurface: Color {
        .themedDial(colorScheme)
    }

    private var textColor: Color {
        .inkPrimary
    }

    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer().frame(height: DS.Spacing.md)

            // Streak number
            Text("\(streakInfo.currentStreak)")
                .font(Font.adaptiveDisplay(size: 80, weight: .semibold, isRegular: isRegular))
                .foregroundStyle(textColor)

            // "DAY STREAK"
            Text(L10n.shareStreakDays)
                .font(.headline)
                .tracking(3)
                .foregroundStyle(textColor.opacity(0.8))

            // Start date
            if let dateStr = formattedStartDate(firstNoBuyDate) {
                Text(L10n.shareSince(dateStr))
                    .font(.caption)
                    .foregroundStyle(textColor.opacity(0.6))
            }

            // Savings goal
            if let goalText = localizedGoalText(savingsGoal) {
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: "target")
                        .font(.caption2)
                        .accessibilityHidden(true)
                    Text(goalText)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(textColor.opacity(0.7))
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.vertical, DS.Spacing.xs)
                .background(
                    Capsule()
                        .fill(textColor.opacity(0.15))
                )
            }

            Spacer()

            // Bottom CTA
            VStack(spacing: DS.Spacing.xs) {
                Rectangle()
                    .fill(textColor.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, DS.Spacing.xxxl)

                Text(L10n.shareNoBuy)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(textColor.opacity(0.7))

                Text("Download NoBuy on the App Store")
                    .font(.caption2)
                    .foregroundStyle(textColor.opacity(0.45))
            }

            Spacer().frame(height: DS.Spacing.lg)
        }
        .frame(width: 360, height: 480)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.sheet)
                .fill(cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.sheet)
                        .strokeBorder(Color.inkHairline, lineWidth: DS.Stroke.bezel)
                )
        )
    }
}

// MARK: - Streak Share Card (Pro)

struct StreakShareCardPro: View {
    let streakInfo: StreakInfo
    var savingsGoal: String = ""
    var firstNoBuyDate: Date?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    private var cardSurface: Color {
        .themedDial(colorScheme)
    }

    private var textColor: Color {
        .inkPrimary
    }

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            // PRO badge
            HStack {
                Spacer()
                Text(L10n.proBadge)
                    .font(.caption2.bold())
                    .foregroundStyle(.accentKept)
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(textColor.opacity(0.9))
                    )
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.top, DS.Spacing.lg)

            // Streak number
            Text("\(streakInfo.currentStreak)")
                .font(Font.adaptiveDisplay(size: 80, weight: .semibold, isRegular: isRegular))
                .foregroundStyle(textColor)

            // "DAY STREAK"
            Text(L10n.shareStreakDays)
                .font(.headline)
                .tracking(3)
                .foregroundStyle(textColor.opacity(0.8))

            // Start date
            if let dateStr = formattedStartDate(firstNoBuyDate) {
                Text(L10n.shareSince(dateStr))
                    .font(.caption)
                    .foregroundStyle(textColor.opacity(0.6))
            }

            // Savings goal
            if let goalText = localizedGoalText(savingsGoal) {
                HStack(spacing: DS.Spacing.xs) {
                    Image(systemName: "target")
                        .font(.caption2)
                        .accessibilityHidden(true)
                    Text(goalText)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(textColor.opacity(0.7))
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.vertical, DS.Spacing.xs)
                .background(
                    Capsule()
                        .fill(textColor.opacity(0.15))
                )
            }

            // Stats row
            HStack(spacing: DS.Spacing.xxxl) {
                VStack(spacing: DS.Spacing.xs) {
                    Text("\(streakInfo.longestStreak)")
                        .font(.title3.bold())
                        .foregroundStyle(textColor)
                    Text(L10n.shareLongest)
                        .font(.caption2)
                        .foregroundStyle(textColor.opacity(0.6))
                }
                VStack(spacing: DS.Spacing.xs) {
                    Text("\(Int(streakInfo.noBuyPercentageThisMonth))%")
                        .font(.title3.bold())
                        .foregroundStyle(textColor)
                    Text(L10n.shareThisMonth)
                        .font(.caption2)
                        .foregroundStyle(textColor.opacity(0.6))
                }
            }
            .padding(.top, DS.Spacing.sm)

            Spacer()

            // Bottom CTA
            VStack(spacing: DS.Spacing.xs) {
                Rectangle()
                    .fill(textColor.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, DS.Spacing.xxxl)

                Text(L10n.shareNoBuy)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(textColor.opacity(0.7))

                Text("Download NoBuy on the App Store")
                    .font(.caption2)
                    .foregroundStyle(textColor.opacity(0.45))
            }

            Spacer().frame(height: DS.Spacing.lg)
        }
        .frame(width: 360, height: 560)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.sheet)
                .fill(cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.sheet)
                        .strokeBorder(Color.inkHairline, lineWidth: DS.Stroke.bezel)
                )
        )
    }
}

#Preview {
    HomeScreen()
        .environment(StoreService.shared)
        .environment(QuickActionHandler())
        .modelContainer(for: [DayRecord.self, MandatoryCategory.self], inMemory: true)
}

// MARK: - Card helpers

private func formattedStartDate(_ date: Date?) -> String? {
    guard let date else { return nil }
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}

private func localizedGoalText(_ goal: String) -> String? {
    guard !goal.isEmpty else { return nil }
    switch goal {
    case "emergencyFund": return L10n.goalEmergencyFund
    case "vacation": return L10n.goalVacation
    case "debtFree": return L10n.goalDebtFree
    case "discipline": return L10n.goalDiscipline
    default: return goal
    }
}

// MARK: - Streak Share Card (Basic)
