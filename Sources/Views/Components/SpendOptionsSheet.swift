import SwiftUI
import SwiftData

struct SpendOptionsSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: HomeViewModel
    let records: [DayRecord]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(L10n.spendTypeQuestion)
                    .font(.headline)
                    .padding(.top, 8)

                // Mandatory only (doesn't break streak)
                Button {
                    viewModel.markSpent(context: modelContext, mandatoryOnly: true, allRecords: records)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "building.columns.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.mandatorySpend)
                                .fontWeight(.semibold)
                            Text(L10n.mandatoryDesc)
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.noBuyGreen)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.mandatoryAmberLight)
                    )
                }
                .buttonStyle(.plain)

                // Discretionary spending (breaks streak)
                Button {
                    viewModel.markSpent(context: modelContext, mandatoryOnly: false, allRecords: records)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "cart.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.discretionarySpend)
                                .fontWeight(.semibold)
                            Text(L10n.discretionaryDesc)
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.spendRed)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.spendRedLight)
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 20)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) { dismiss() }
                }
            }
        }
    }
}
