import SwiftData
import SwiftUI
import WidgetKit

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
    @State private var saveError: String?
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

    /// The one place a record becomes a truth, shared with the widget's reader so the calendar,
    /// the sheet that edits it and the Lock Screen can never disagree about what a day is.
    private func truth(of record: DayRecord) -> DayTruth {
        NoBuySnapshotReader.truth(of: record)
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
                                    .surfaceDial
                                )
                        )

                    if let record = existingRecord {
                        HStack {
                            DayMark(truth: truth(of: record))
                                .accessibilityHidden(true)
                            Text(truth(of: record).spokenName.capitalizedFirst)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, DS.Spacing.sm)
                        .padding(.horizontal, DS.Spacing.lg)
                        .background(
                            Capsule().fill(record.isNoBuyDay ? Color.accentKeptWash : Color.accentSpentWash)
                        )
                    }

                    // Note field
                    TextField(
                        "Add a note (optional)",
                        text: $noteText,
                        axis: .vertical
                    )
                    .lineLimit(2 ... 4)
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
                                Image(systemName: "shield")
                                    .foregroundStyle(.accentKept)
                                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                                    Text("Spend a freeze")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("The run is bridged, not broken")
                                        .font(.caption)
                                        .foregroundStyle(.inkSecondary)
                                }
                            }
                        }
                        .tint(.accentKept)
                        .padding(DS.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                .fill(Color.accentKeptWash)
                        )

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
                            Image(systemName: "checkmark.circle")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                                Text(L10n.noBuyButton)
                                    .fontWeight(.semibold)
                                Text("The run continues")
                                    .font(.caption)
                                    .foregroundStyle(.inkSecondary)
                            }
                            Spacer()
                        }
                        .padding(DS.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                .fill(Color.accentKeptWash)
                        )

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
                            Image(systemName: "building.columns")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                                Text(L10n.mandatorySpend)
                                    .fontWeight(.semibold)
                                Text(L10n.mandatoryDesc)
                                    .font(.caption)
                                    .foregroundStyle(.inkSecondary)
                            }
                            Spacer()
                        }
                        .padding(DS.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                .fill(Color.stateWaitWash)
                        )

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
                            Image(systemName: "cart")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                                Text(L10n.discretionarySpend)
                                    .fontWeight(.semibold)
                                Text(L10n.discretionaryDesc)
                                    .font(.caption)
                                    .foregroundStyle(.inkSecondary)
                            }
                            Spacer()
                        }
                        .padding(DS.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                .fill(Color.accentSpentWash)
                        )

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
                                    .accessibilityHidden(true)
                                Text("Delete this day")
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
                                    do {
                                        try modelContext.save()
                                        WidgetCenter.shared.reloadAllTimelines()
                                    } catch {
                                        saveError = "Failed to delete: \(error.localizedDescription)"
                                    }
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
            .background(DS.Gradient.glow.opacity(0.3).ignoresSafeArea())
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
        .alert("Error", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "An unexpected error occurred.")
        }
    }

    @Query(sort: \DayRecord.date, order: .reverse) private var allRecords: [DayRecord]

    private func markDay(didSpend: Bool, mandatoryOnly: Bool) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedAmount = Double(amountText.replacingOccurrences(of: ",", with: "."))

        let savedRecord: DayRecord
        if let existing = existingRecord {
            existing.didSpend = didSpend
            existing.isMandatoryOnly = mandatoryOnly
            existing.note = trimmedNote.isEmpty ? nil : trimmedNote
            existing.amount = didSpend ? parsedAmount : nil
            // Apply freeze toggle for spending days
            existing.isFrozen = didSpend && !mandatoryOnly && isFrozen
            savedRecord = existing
        } else {
            let record = DayRecord(
                date: normalizedDate,
                didSpend: didSpend,
                isMandatoryOnly: mandatoryOnly,
                note: trimmedNote.isEmpty ? nil : trimmedNote,
                amount: didSpend ? parsedAmount : nil
            )
            modelContext.insert(record)
            savedRecord = record
        }

        do {
            try modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            saveError = "Failed to save: \(error.localizedDescription)"
            return
        }

        // Check achievements over the saved set: a brand-new record may not yet
        // be in the @Query snapshot, so include it explicitly.
        var updatedRecords = allRecords.filter { calendar.startOfDay(for: $0.date) != normalizedDate }
        updatedRecords.append(savedRecord)
        let streakInfo = StreakCalculator.calculate(from: updatedRecords)
        let totalNoBuyDays = updatedRecords.filter(\.isNoBuyDay).count
        AchievementManager.shared.checkAchievements(
            currentStreak: streakInfo.currentStreak,
            totalNoBuyDays: totalNoBuyDays,
            records: updatedRecords
        )

        // Genuine positive moment: a no-spend day that lands on a streak milestone.
        // Arms the pre-prompt card; CalendarScreen surfaces it once this sheet closes.
        if !didSpend, !mandatoryOnly {
            RatingPrompt.shared.noteMilestone(currentStreak: streakInfo.currentStreak)
        }

        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    // swiftlint:disable:next force_try
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
