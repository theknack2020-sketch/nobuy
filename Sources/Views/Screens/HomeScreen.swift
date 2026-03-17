import SwiftUI
import SwiftData

struct HomeScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DayRecord.date, order: .reverse) private var records: [DayRecord]
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePrimary
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()
                    streakBadge
                    mainButton
                    todayStatus
                    Spacer()
                    monthlySummaryCard
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .navigationTitle(L10n.appTitle)
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.loadToday(records: records)
        }
        .onChange(of: records.count) {
            viewModel.loadToday(records: records)
        }
        .sheet(isPresented: $viewModel.showSpendOptions) {
            SpendOptionsSheet(viewModel: viewModel, records: records)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Streak Badge

    private var streakBadge: some View {
        VStack(spacing: 8) {
            Text("\(viewModel.streakInfo.currentStreak)")
                .font(.system(size: 80, weight: .black, design: .rounded))
                .foregroundStyle(viewModel.streakInfo.currentStreak > 0 ? Color.noBuyGreen : Color.textTertiary)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.4), value: viewModel.streakInfo.currentStreak)

            Text(L10n.dayStreak)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.textSecondary)
                .textCase(.uppercase)
                .tracking(2)

            if viewModel.streakInfo.longestStreak > 0 {
                Text(L10n.longestStreak(viewModel.streakInfo.longestStreak))
                    .font(.caption)
                    .foregroundStyle(.textTertiary)
            }
        }
    }

    // MARK: - Main Button

    @ViewBuilder
    private var mainButton: some View {
        VStack(spacing: 0) {
            Button {
                if viewModel.isTodayRecorded && viewModel.isTodayNoBuy {
                    viewModel.showSpendOptions = true
                } else if viewModel.isTodayRecorded && !viewModel.isTodayNoBuy {
                    viewModel.markNoBuy(context: modelContext, allRecords: records)
                } else {
                    viewModel.markNoBuy(context: modelContext, allRecords: records)
                }
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: viewModel.isTodayNoBuy ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 56))
                        .symbolEffect(.bounce, value: viewModel.isTodayNoBuy)

                    Text(viewModel.isTodayNoBuy ? L10n.noBuyDone : L10n.noBuyButton)
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .foregroundStyle(viewModel.isTodayNoBuy ? .white : Color.noBuyGreen)
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(viewModel.isTodayNoBuy ? Color.noBuyGreen : Color.noBuyGreenLight)
                )
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.7), trigger: viewModel.isTodayNoBuy)

            if !viewModel.isTodayRecorded || viewModel.isTodayNoBuy {
                Button {
                    viewModel.showSpendOptions = true
                } label: {
                    Text(L10n.spentButton)
                        .font(.subheadline)
                        .foregroundStyle(.spendRed)
                }
                .padding(.top, 12)
            }
        }
    }

    // MARK: - Today Status

    private var todayStatus: some View {
        Text(viewModel.todayStatusText)
            .font(.callout)
            .foregroundStyle(.textSecondary)
            .animation(.easeInOut, value: viewModel.todayStatusText)
    }

    // MARK: - Monthly Summary

    private var monthlySummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.noBuyGreen)
                Text(L10n.thisMonth)
                    .fontWeight(.semibold)
                Spacer()
            }

            HStack(spacing: 4) {
                Text("\(viewModel.streakInfo.noBuyDaysThisMonth)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.noBuyGreen)

                Text(L10n.monthSummary(viewModel.streakInfo.noBuyDaysThisMonth, viewModel.streakInfo.totalDaysThisMonth))
                    .font(.callout)
                    .foregroundStyle(.textSecondary)

                Spacer()

                Text("\(Int(viewModel.streakInfo.noBuyPercentageThisMonth))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.noBuyGreen)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.surfaceTertiary)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.noBuyGreen)
                        .frame(
                            width: geo.size.width * viewModel.streakInfo.noBuyPercentageThisMonth / 100,
                            height: 8
                        )
                        .animation(.spring(duration: 0.5), value: viewModel.streakInfo.noBuyPercentageThisMonth)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfaceSecondary)
        )
    }
}

#Preview {
    HomeScreen()
        .modelContainer(for: [DayRecord.self, MandatoryCategory.self], inMemory: true)
}
