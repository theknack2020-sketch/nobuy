import SwiftUI
import SwiftData

struct DayEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let existingRecord: DayRecord?
    @State private var noteText: String = ""
    @State private var amountText: String = ""
    @State private var isFrozen: Bool = false
    @State private var appeared = false
    @State private var showDeleteConfirmation = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "d MMMM EEEE"
        return formatter.string(from: date)
    }

    /// Whether the existing record represents a spending day (not frozen, not no-buy)
    private var isSpendingRecord: Bool {
        guard let record = existingRecord else { return false }
        return record.didSpend && !record.isMandatoryOnly
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.xl) {
                    // Date header with gradient
                    Text(dateString)
                        .font(.headline)
                        .padding(.top, DS.Spacing.sm)
                        .padding(.horizontal, DS.Spacing.lg)
                        .padding(.vertical, DS.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.surfaceSecondary, .surfaceTertiary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )

                    if let record = existingRecord {
                        HStack {
                            Image(systemName: record.isNoBuyDay ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(record.isNoBuyDay ? .noBuyGreen : .spendRed)
                            Text(record.isNoBuyDay
                                 ? "No-spend day"
                                 : "Spent")
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, DS.Spacing.sm)
                        .padding(.horizontal, DS.Spacing.lg)
                        .background(
                            Capsule().fill(record.isNoBuyDay ? Color.noBuyGreenLight : Color.spendRedLight)
                        )
                    }

                    // Note field
                    TextField(
                        "Add a note (optional)",
                        text: $noteText,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
                    .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7), value: appeared)

                    // Amount field — shown when existing record has spending
                    if let record = existingRecord, record.didSpend {
                        TextField(
                            "Amount",
                            text: $amountText
                        )
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 15)
                        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7).delay(0.05), value: appeared)
                    }

                    // Freeze toggle — shown when existing record is a discretionary spend
                    if isSpendingRecord {
                        Toggle(isOn: $isFrozen) {
                            HStack(spacing: DS.Spacing.sm) {
                                Image(systemName: "shield.fill")
                                    .foregroundStyle(.noBuyGreen)
                                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                                    Text("Mark as Freeze")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Streak is preserved")
                                        .font(.caption)
                                        .foregroundStyle(.textSecondary)
                                }
                            }
                        }
                        .tint(.noBuyGreen)
                        .padding(DS.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                .fill(Color.noBuyGreenLight)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 15)
                        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7).delay(0.1), value: appeared)
                        .onChange(of: isFrozen) { _, _ in
                            HapticManager.toggle()
                        }
                    }

                    Button {
                        HapticManager.success()
                        SoundManager.playIfEnabled(.save)
                        markDay(didSpend: false, mandatoryOnly: false)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                                Text(L10n.noBuyButton)
                                    .fontWeight(.semibold)
                                Text("Included in streak")
                                    .font(.caption)
                                    .foregroundStyle(.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(DS.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                .fill(Color.noBuyGreenLight)
                        )
                        .shadow(color: .noBuyGreen.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.scale)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7).delay(0.1), value: appeared)
                    .accessibilityLabel("Mark as no-spend day")
                    .accessibilityHint("Double tap to mark this day as no-spend")

                    Button {
                        HapticManager.tap()
                        SoundManager.playIfEnabled(.save)
                        markDay(didSpend: true, mandatoryOnly: true)
                    } label: {
                        HStack {
                            Image(systemName: "building.columns.fill")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                                Text(L10n.mandatorySpend)
                                    .fontWeight(.semibold)
                                Text(L10n.mandatoryDesc)
                                    .font(.caption)
                                    .foregroundStyle(.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(DS.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                .fill(Color.mandatoryAmberLight)
                        )
                        .shadow(color: .mandatoryAmber.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.scale)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7).delay(0.15), value: appeared)
                    .accessibilityLabel("Mark as essential spending")
                    .accessibilityHint("Double tap to mark this as a necessary expense")

                    Button {
                        HapticManager.warning()
                        SoundManager.playIfEnabled(.save)
                        markDay(didSpend: true, mandatoryOnly: false)
                    } label: {
                        HStack {
                            Image(systemName: "cart.fill")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                                Text(L10n.discretionarySpend)
                                    .fontWeight(.semibold)
                                Text(L10n.discretionaryDesc)
                                    .font(.caption)
                                    .foregroundStyle(.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(DS.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                .fill(Color.spendRedLight)
                        )
                        .shadow(color: .spendRed.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.scale)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7).delay(0.2), value: appeared)
                    .accessibilityLabel("Mark as discretionary spending")
                    .accessibilityHint("Double tap to mark this as non-essential spending")

                    if existingRecord != nil {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Record")
                            }
                            .font(.subheadline)
                        }
                        .confirmationDialog(
                            "Delete this record?",
                            isPresented: $showDeleteConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("Delete", role: .destructive) {
                                HapticManager.delete()
                                SoundManager.playIfEnabled(.delete)
                                if let record = existingRecord {
                                    modelContext.delete(record)
                                    try? modelContext.save()
                                }
                                dismiss()
                            }
                        } message: {
                            Text("This action cannot be undone.")
                        }
                        .padding(.top, DS.Spacing.xs)
                        .accessibilityLabel("Delete this day's record")
                        .accessibilityHint("Double tap to permanently delete this record")
                    }

                    Spacer()
                        .frame(height: DS.Spacing.xxl)
                }
                .padding(.horizontal, DS.Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) {
                        HapticManager.tap()
                        dismiss()
                    }
                    .accessibilityIdentifier("day_edit_cancel")
                }
            }
            .onAppear {
                noteText = existingRecord?.note ?? ""
                if let amount = existingRecord?.amount {
                    amountText = String(format: "%.2f", amount)
                }
                isFrozen = existingRecord?.isFrozen ?? false
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(DS.Anim.stagger)) {
                        appeared = true
                    }
                }
            }
        }
    }

    @Query(sort: \DayRecord.date, order: .reverse) private var allRecords: [DayRecord]

    private func markDay(didSpend: Bool, mandatoryOnly: Bool) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedAmount = Double(amountText.replacingOccurrences(of: ",", with: "."))

        if let existing = existingRecord {
            existing.didSpend = didSpend
            existing.isMandatoryOnly = mandatoryOnly
            existing.note = trimmedNote.isEmpty ? nil : trimmedNote
            existing.amount = didSpend ? parsedAmount : nil
            // Apply freeze toggle for spending days
            existing.isFrozen = didSpend && !mandatoryOnly && isFrozen
        } else {
            let record = DayRecord(
                date: normalizedDate,
                didSpend: didSpend,
                isMandatoryOnly: mandatoryOnly,
                note: trimmedNote.isEmpty ? nil : trimmedNote,
                amount: didSpend ? parsedAmount : nil
            )
            modelContext.insert(record)
        }

        try? modelContext.save()

        // Check achievements with updated record set
        let streakInfo = StreakCalculator.calculate(from: allRecords)
        let totalNoBuyDays = allRecords.filter(\.isNoBuyDay).count
        AchievementManager.shared.checkAchievements(
            currentStreak: streakInfo.currentStreak,
            totalNoBuyDays: totalNoBuyDays,
            records: allRecords
        )

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: DayRecord.self, configurations: config)

    // Seed sample data for preview
    let context = container.mainContext
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
    let sampleRecord = DayRecord(
        date: yesterday,
        didSpend: true,
        isMandatoryOnly: false,
        note: "Coffee",
        amount: 45.50
    )
    context.insert(sampleRecord)

    return DayEditSheet(date: yesterday, existingRecord: sampleRecord)
        .modelContainer(container)
}
