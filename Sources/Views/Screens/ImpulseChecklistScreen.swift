import SwiftUI

// MARK: - Impulse checklist — five questions before a purchase (Escapement, v2.0.0)
//
// Opened mid-craving, in a shop, one-handed. The v1 screen asked one question per page with a
// halo, a gradient answer pad and confetti on the "right" answer; this one is a single list the
// user can read in one glance, answer in any order, and leave half-finished.
//
// Four decisions the round made that this file must not quietly undo:
//
//   · **The verdict slot is fixed from the first pixel** (M-05). It renders before anything is
//     answered — an `if` that removes it would make the screen jump under the thumb at exactly
//     the moment someone is deciding whether to spend money.
//   · **The list takes sides only in AGGREGATE.** No single answer is celebrated, scolded or
//     coloured as correct; the lean lives in a seated tick and the count, nothing else.
//   · **Both exits are dignified.** "Hold it 24 hours" and "Buy it anyway" are the same size and
//     the same voice. The product records a purchase, it does not comment on it — so there is
//     no confetti here, and no warning triangle either.
//   · **Partial answers count.** "Answer what you can" is the honest instruction: someone
//     standing at a till will answer two of five, and two of five is a real reading.

struct ImpulseChecklistScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Called when the user leaves without buying — the caller records the day.
    var onDecidedNotToBuy: (() -> Void)?
    /// Set when the checklist is opened about a specific thing (from the spend sheet).
    var prefilledItemName: String?

    @State private var store = ChecklistStore.shared
    /// question id → the user picked the LEFT answer.
    @State private var answers: [UUID: Bool] = [:]
    @State private var itemName = ""
    @State private var itemAmount = ""
    @State private var isEditingItem = false
    @State private var isEditingList = false
    @State private var heldUntil: Date?

    private enum ItemField { case name, amount }
    @FocusState private var itemFocus: ItemField?

    private var reading: ChecklistReading {
        ChecklistReading(questions: store.questions, answers: answers)
    }

    private var trimmedItemName: String {
        itemName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    itemChip

                    ForEach(store.questions) { question in
                        questionRow(question)
                    }

                    verdictSlot

                    exits
                }
                .padding(.horizontal, DS.Spacing.screenGutter)
                .padding(.bottom, DS.Spacing.xxxl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.surfaceField)
            .navigationTitle("Before you buy")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Today") { dismiss() }
                        .font(.subheadline)
                        .accessibilityIdentifier("impulse_close")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { isEditingList = true }
                        .font(.subheadline)
                        .accessibilityIdentifier("impulse_edit")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { itemFocus = nil }
                }
            }
            .sheet(isPresented: $isEditingList) {
                ChecklistEditSheet(store: store)
            }
        }
        .onAppear {
            if let prefilledItemName, itemName.isEmpty {
                itemName = prefilledItemName
            }
        }
    }

    // MARK: - The thing being weighed

    @ViewBuilder
    private var itemChip: some View {
        if isEditingItem || !trimmedItemName.isEmpty {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                TextField("What is it?", text: $itemName)
                    .font(.headline)
                    .focused($itemFocus, equals: .name)
                    .submitLabel(.next)
                    .onSubmit { itemFocus = .amount }
                    .accessibilityIdentifier("impulse_item_name")

                TextField("Price — optional, never summed", text: $itemAmount)
                    .font(.subheadline)
                    .foregroundStyle(.inkSecondary)
                    .focused($itemFocus, equals: .amount)
                    .submitLabel(.done)
                    .onSubmit { itemFocus = nil }
                    .accessibilityIdentifier("impulse_item_amount")
            }
            .padding(DS.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(card)
        } else {
            Button {
                isEditingItem = true
                itemFocus = .name
            } label: {
                // Two lines, not one wrapped sentence: the state comes first and the invitation
                // sits under it, so neither breaks mid-phrase at large type sizes.
                VStack(alignment: .leading, spacing: 2) {
                    Text("No item attached")
                        .font(.subheadline)
                        .foregroundStyle(.inkSecondary)
                    Text("Answer in the abstract, or add one")
                        .font(.footnote)
                        .foregroundStyle(.inkSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DS.Spacing.lg)
                .background(card)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("impulse_attach_item")
            .accessibilityLabel("No item attached. Add one, or answer in the abstract.")
        }
    }

    // MARK: - A question

    @ViewBuilder
    private func questionRow(_ question: ChecklistQuestion) -> some View {
        if let pickedLeft = answers[question.id] {
            answeredRow(question, pickedLeft: pickedLeft)
        } else {
            unansweredRow(question)
        }
    }

    private func unansweredRow(_ question: ChecklistQuestion) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text(question.text)
                .font(.body)
                .foregroundStyle(.inkPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Neither button is the good one, so neither carries the accent. The words differ;
            // the weight does not.
            HStack(spacing: DS.Spacing.md) {
                answerButton(question, pickedLeft: true)
                answerButton(question, pickedLeft: false)
            }
        }
        .padding(DS.Spacing.lg)
        .background(card)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(question.text)
    }

    private func answerButton(_ question: ChecklistQuestion, pickedLeft: Bool) -> some View {
        Button {
            HapticManager.tap()
            withAnimation(reduceMotion ? nil : DS.Anim.functional) {
                answers[question.id] = pickedLeft
            }
        } label: {
            Text(question.answerLabel(pickedLeft: pickedLeft))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.inkPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .fill(Color.surfaceField)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.sm)
                                .strokeBorder(Color.inkHairline, lineWidth: DS.Stroke.hairline)
                        )
                )
        }
        .buttonStyle(.scale)
        .accessibilityIdentifier("impulse_answer_\(pickedLeft ? "left" : "right")_\(question.id.uuidString.prefix(8))")
    }

    /// Answered: the row collapses to its answer and seats a tick. Left-leaning is waiting,
    /// right-leaning is buying — the same grammar the calendar uses for a day's truth.
    private func answeredRow(_ question: ChecklistQuestion, pickedLeft: Bool) -> some View {
        let leansWait = question.leansToWaiting(pickedLeft: pickedLeft)

        return Button {
            HapticManager.tap()
            withAnimation(reduceMotion ? nil : DS.Anim.functional) {
                answers[question.id] = nil
            }
        } label: {
            HStack(spacing: DS.Spacing.md) {
                seatedTick(leansWait: leansWait)

                VStack(alignment: .leading, spacing: 2) {
                    Text(question.shortLabel)
                        .font(.caption)
                        .foregroundStyle(.inkSecondary)
                    Text(question.answerLabel(pickedLeft: pickedLeft))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.inkPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(DS.Spacing.lg)
            .frame(minHeight: 44)
            .background(card)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(question.shortLabel): \(question.answerLabel(pickedLeft: pickedLeft)). Points to \(leansWait ? "waiting" : "buying").")
        .accessibilityHint("Double tap to answer again")
        .accessibilityIdentifier("impulse_answered_\(question.id.uuidString.prefix(8))")
    }

    /// The lean, carried by DIRECTION alone: left is waiting, right is buying.
    ///
    /// One colour for both, deliberately. Two colours would make the tick say "good" and "bad"
    /// about a single answer, and this list takes sides only in aggregate — and it would spend
    /// the kept accent on something that is not a kept day. Direction is also the channel that
    /// survives Differentiate Without Colour (M-15), so the reading is the same for everyone.
    ///
    /// `IndexTriangle` points DOWN at rest, and `rotationEffect` is clockwise-positive: +90°
    /// seats it left, −90° seats it right.
    private func seatedTick(leansWait: Bool) -> some View {
        IndexTriangle()
            .fill(Color.inkSecondary)
            .frame(width: 10, height: 8)
            .rotationEffect(.degrees(leansWait ? 90 : -90))
            .frame(width: 18)
            .accessibilityHidden(true)
    }

    // MARK: - The verdict slot (always present)

    private var verdictSlot: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text(reading.headline)
                .font(.headline)
                .foregroundStyle(reading.answered > 0 ? .inkPrimary : .inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let reasonLine = reading.reasonLine {
                Text(reasonLine)
                    .font(.footnote)
                    .foregroundStyle(.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, DS.Spacing.sm)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(reading.spoken)
        .accessibilityIdentifier("impulse_verdict")
    }

    // MARK: - Two exits, level

    private var exits: some View {
        VStack(spacing: DS.Spacing.sm) {
            Button {
                hold()
            } label: {
                Text("Hold it 24 hours")
                    .font(.headline)
                    .foregroundStyle(reading.anythingLeansToWaiting ? Color.inkOnAccent : Color.inkSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        Capsule()
                            .fill(reading.anythingLeansToWaiting ? Color.accentKept : Color.surfaceWell)
                            .overlay(
                                Capsule().strokeBorder(Color.inkHairline, lineWidth: DS.Stroke.hairline)
                            )
                    )
            }
            .buttonStyle(.scale)
            .accessibilityIdentifier("impulse_hold")

            Button {
                // Recorded, never bannered: the product does not scold a purchase.
                HapticManager.tap()
                dismiss()
            } label: {
                Text("Buy it anyway")
                    .font(.headline)
                    .foregroundStyle(.inkPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        Capsule()
                            .fill(Color.surfaceWell)
                            .overlay(
                                Capsule().strokeBorder(Color.inkHairline, lineWidth: DS.Stroke.hairline)
                            )
                    )
            }
            .buttonStyle(.scale)
            .accessibilityIdentifier("impulse_buy_anyway")

            // The consequence of holding, stated before it happens and again after.
            Text(holdFootnote)
                .font(.footnote)
                .foregroundStyle(.inkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.top, DS.Spacing.xs)
        }
        .padding(.top, DS.Spacing.sm)
    }

    private var holdFootnote: String {
        if let heldUntil {
            return "Held. It can be bought \(Self.relativeClock(heldUntil))."
        }
        if trimmedItemName.isEmpty {
            return "Holding adds it to the waiting list — name it first, so the list holds a thing rather than a feeling."
        }
        return "Holding adds it to the waiting list — it can be bought \(Self.relativeClock(Date.now.addingTimeInterval(24 * 3600)))."
    }

    // MARK: - Actions

    private func hold() {
        guard !trimmedItemName.isEmpty else {
            // Nothing to hold yet: open the field rather than refusing silently.
            HapticManager.warning()
            withAnimation(reduceMotion ? nil : DS.Anim.functional) { isEditingItem = true }
            itemFocus = .name
            return
        }

        let amount = Double(itemAmount.replacingOccurrences(of: ",", with: "."))
        let item = WaitingItem(name: trimmedItemName, estimatedCost: amount, reminderHours: 24)
        WaitingListManager.shared.addItem(item)
        HapticManager.save()
        heldUntil = Date.now.addingTimeInterval(24 * 3600)
        recordOutcome(didBuy: false)
        onDecidedNotToBuy?()
        dismiss()
    }

    /// The two counters Stats reads. Kept as plain integers — this is the app's own bookkeeping,
    /// not analytics, and it never leaves the device.
    private func recordOutcome(didBuy: Bool) {
        let completions = UserDefaults.standard.integer(forKey: "impulseChecklistCompletions")
        UserDefaults.standard.set(completions + 1, forKey: "impulseChecklistCompletions")
        guard !didBuy else { return }
        let saved = UserDefaults.standard.integer(forKey: "impulseChecklistSaved")
        UserDefaults.standard.set(saved + 1, forKey: "impulseChecklistSaved")
    }

    private static func relativeClock(_ date: Date) -> String {
        let time = date.formatted(date: .omitted, time: .shortened)
        return Calendar.current.isDateInToday(date) ? "at \(time)" : "tomorrow at \(time)"
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: DS.Radius.md)
            .fill(Color.surfaceWell)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .strokeBorder(Color.inkHairline, lineWidth: DS.Stroke.hairline)
            )
    }
}

// MARK: - Edit the questions
//
// The user's own records, so all three verbs are here: add, remove, reorder. Removal is
// reversible for five seconds — a wrong deletion is never permanent (finished-product law 2).

struct ChecklistEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: ChecklistStore

    @State private var isAdding = false
    @State private var draftText = ""
    @State private var draftWaitIsLeft = false
    @FocusState private var draftFocused: Bool
    /// Removal is guarded twice — a confirmation before, a five-second undo after. Measured on
    /// device: five seconds is a courtesy, not a safety net, because a toast can be missed
    /// entirely; and a custom question is the user's OWN sentence, which nothing can retype for
    /// them. So the confirmation is the guard and the toast is the second chance.
    @State private var pendingConfirmation: ChecklistQuestion?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                List {
                    Section {
                        ForEach(store.questions) { question in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(question.text)
                                    .font(.subheadline)
                                    .foregroundStyle(.inkPrimary)
                                Text("\(question.waitAnswer) means wait")
                                    .font(.caption2)
                                    .foregroundStyle(.inkSecondary)
                            }
                            .padding(.vertical, 2)
                        }
                        .onDelete { offsets in
                            guard let index = offsets.first, store.questions.indices.contains(index)
                            else { return }
                            pendingConfirmation = store.questions[index]
                        }
                        .onMove { source, destination in
                            store.move(from: source, to: destination)
                        }
                    } header: {
                        Text("Yours to shape. The five stock questions can be removed too.")
                            .textCase(nil)
                            .font(.footnote)
                            .foregroundStyle(.inkSecondary)
                    }

                    Section {
                        Button("Add a question") {
                            isAdding = true
                            draftFocused = true
                        }
                        .accessibilityIdentifier("checklist_add_question")

                        if store.isMissingStockQuestions {
                            Button("Bring back the stock questions") {
                                store.restoreStockQuestions()
                            }
                            .accessibilityIdentifier("checklist_restore_stock")
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.surfaceField)

                if let pending = store.pendingRemoval {
                    undoToast(for: pending)
                        .padding(.horizontal, DS.Spacing.lg)
                        .padding(.bottom, DS.Spacing.lg)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(DS.Anim.functional, value: store.pendingRemoval)
            .navigationTitle("Edit the questions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        store.clearPendingRemoval()
                        dismiss()
                    }
                    .accessibilityIdentifier("checklist_edit_done")
                }
                ToolbarItem(placement: .primaryAction) { EditButton() }
            }
            .sheet(isPresented: $isAdding) { addSheet }
            .confirmationDialog(
                "Remove this question?",
                isPresented: Binding(
                    get: { pendingConfirmation != nil },
                    set: { if !$0 { pendingConfirmation = nil } }
                ),
                titleVisibility: .visible,
                presenting: pendingConfirmation
            ) { question in
                Button("Remove", role: .destructive) {
                    store.remove(question)
                    pendingConfirmation = nil
                }
                Button("Keep it", role: .cancel) { pendingConfirmation = nil }
            } message: { question in
                Text(question.isStock
                    ? "\u{201C}\(question.text)\u{201D} — you can bring the stock five back at any time."
                    : "\u{201C}\(question.text)\u{201D} — this one is yours, and only the undo that follows can bring it back.")
            }
        }
    }

    private func undoToast(for pending: ChecklistStore.PendingRemoval) -> some View {
        HStack(spacing: DS.Spacing.md) {
            Text("Removed \u{201C}\(pending.question.shortLabel)\u{201D}")
                .font(.footnote)
                .foregroundStyle(.surfaceField)
                .lineLimit(1)

            Spacer(minLength: DS.Spacing.sm)

            Button("Undo") { store.undoRemoval() }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.surfaceField)
                .accessibilityIdentifier("checklist_undo_remove")
        }
        .padding(.horizontal, DS.Spacing.lg)
        .frame(height: 44)
        .background(Capsule().fill(Color.inkPrimary))
    }

    /// Adding a question asks the one thing the app cannot infer: which answer means wait.
    /// "Do I already own one?" leans wait on YES and "Do I have space?" leans wait on NO — a
    /// guessed default would miscount half the questions people actually write.
    private var addSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Ask yourself…", text: $draftText, axis: .vertical)
                        .lineLimit(1 ... 3)
                        .focused($draftFocused)
                        .accessibilityIdentifier("checklist_draft_text")
                }

                Section {
                    Picker("Which answer means wait?", selection: $draftWaitIsLeft) {
                        Text("Yes").tag(true)
                        Text("No").tag(false)
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text("The checklist counts leanings, so it has to know which way yours points.")
                }
            }
            .navigationTitle("New question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { closeAddSheet() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        store.add(text: draftText, waitIsLeft: draftWaitIsLeft)
                        closeAddSheet()
                    }
                    .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("checklist_confirm_add")
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func closeAddSheet() {
        draftText = ""
        draftWaitIsLeft = false
        isAdding = false
    }
}

#Preview("Fresh") {
    ImpulseChecklistScreen()
}

#Preview("With an item") {
    ImpulseChecklistScreen(prefilledItemName: "linen shirt")
}
