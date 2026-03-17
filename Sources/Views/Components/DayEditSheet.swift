import SwiftUI
import SwiftData

struct DayEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let existingRecord: DayRecord?

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM EEEE"
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(dateString)
                    .font(.headline)
                    .padding(.top, 8)

                if let record = existingRecord {
                    // Show current status
                    HStack {
                        Image(systemName: record.isNoBuyDay ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(record.isNoBuyDay ? .noBuyGreen : .spendRed)
                        Text(record.isNoBuyDay ? "Harcamasız gün" : "Harcama yapıldı")
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 8)
                }

                // No-buy option
                Button {
                    markDay(didSpend: false, mandatoryOnly: false)
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Harcama Yapmadım")
                                .fontWeight(.semibold)
                            Text("Streak'e dahil edilir")
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.noBuyGreenLight)
                    )
                }
                .buttonStyle(.plain)

                // Mandatory only
                Button {
                    markDay(didSpend: true, mandatoryOnly: true)
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
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.mandatoryAmberLight)
                    )
                }
                .buttonStyle(.plain)

                // Discretionary spend
                Button {
                    markDay(didSpend: true, mandatoryOnly: false)
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
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.spendRedLight)
                    )
                }
                .buttonStyle(.plain)

                // Delete record if exists
                if existingRecord != nil {
                    Button(role: .destructive) {
                        if let record = existingRecord {
                            modelContext.delete(record)
                            try? modelContext.save()
                        }
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Kaydı Sil")
                        }
                        .font(.subheadline)
                    }
                    .padding(.top, 4)
                }

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

    private func markDay(didSpend: Bool, mandatoryOnly: Bool) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        if let existing = existingRecord {
            existing.didSpend = didSpend
            existing.isMandatoryOnly = mandatoryOnly
        } else {
            let record = DayRecord(date: normalizedDate, didSpend: didSpend, isMandatoryOnly: mandatoryOnly)
            modelContext.insert(record)
        }

        try? modelContext.save()
        HapticManager.impact(.medium)
        dismiss()
    }
}
