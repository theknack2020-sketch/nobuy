import SwiftUI

struct WaitingListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreService.self) private var store
    @State private var showPaywall = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    private var manager = WaitingListManager.shared

    @State private var showAddForm = false
    @State private var newItemName = ""
    @State private var newItemCost = ""
    @State private var selectedHours = 24
    @State private var appeared = false

    private let reminderOptions = [24, 48, 72]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceField.ignoresSafeArea()
                DS.Gradient.glow.opacity(0.5).ignoresSafeArea()

                if manager.activeItems.isEmpty, manager.resolvedItems.isEmpty {
                    emptyState
                } else {
                    listContent
                }
            }
            .navigationTitle("Waiting List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        HapticManager.tap()
                        dismiss()
                    }
                    .accessibilityIdentifier("waiting_list_close")
                }
                ToolbarItem(placement: .primaryAction) {
                    // Three slots free, unlimited on Pro (docs/FREE-TIER.md). The wait itself
                    // is never gated — what Pro buys is holding MORE things at once, and the
                    // paywall names the limit in the user's own numbers rather than shrugging.
                    Button {
                        let held = manager.activeItems.count
                        guard store.canHoldAnotherItem(currentCount: held) else {
                            HapticManager.tap()
                            showPaywall = true
                            return
                        }
                        HapticManager.tap()
                        SoundManager.playIfEnabled(.tap)
                        showAddForm = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.accentKept)
                    }
                    .buttonStyle(.scale)
                    .accessibilityLabel("Add new item to waiting list")
                    .accessibilityIdentifier("waiting_list_add")
                }
            }
            .sheet(isPresented: $showAddForm) {
                addItemSheet
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView(
                    store: store,
                    entry: .waitingSlots(
                        used: manager.activeItems.count,
                        limit: StoreService.freeWaitingSlots
                    )
                )
            }
        }
    }

    // MARK: - List Content

    private var listContent: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.xxl) {
                // Saved money banner
                if manager.savedMoney > 0 {
                    savedMoneyBanner
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7), value: appeared)
                }

                // Active items
                if !manager.activeItems.isEmpty {
                    activeSection
                }

                // Resolved items
                if !manager.resolvedItems.isEmpty {
                    resolvedSection
                }
            }
            .padding(.horizontal, DS.Spacing.xl)
            .padding(.top, DS.Spacing.md)
            .padding(.bottom, DS.Spacing.xxxl)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }

    // MARK: - Saved Money Banner

    private var savedMoneyBanner: some View {
        HStack(spacing: DS.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        .accentKept.opacity(0.12)
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: "leaf")
                    .font(.title3)
                    .foregroundStyle(.accentKept)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("Saved by not buying")
                    .font(.caption)
                    .foregroundStyle(.inkSecondary)
                Text(formattedSavedMoney)
                    .font(Font.adaptiveDisplay(size: 24, weight: .semibold, isRegular: isRegular))
                    .foregroundStyle(
                        .accentKept
                    )
            }

            Spacer()
        }
        .padding(DS.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg)
                .fill(Color.accentKept.opacity(0.08))
        )

        .pressable()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Saved by not buying: \(formattedSavedMoney)")
    }

    private var formattedSavedMoney: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: manager.savedMoney)) ?? "$\(Int(manager.savedMoney))"
    }

    // MARK: - Active Section

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.accentKept)
                Text("Waiting")
                    .font(.headline)
                    .foregroundStyle(.inkPrimary)
                Spacer()
                Text("\(manager.activeItems.count)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.accentKept)
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(Capsule().fill(Color.accentKeptWash))
            }

            ForEach(manager.activeItems) { item in
                activeItemRow(item)
            }

        }
    }

    private func activeItemRow(_ item: WaitingItem) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: DS.Spacing.md) {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.inkPrimary)

                    HStack(spacing: DS.Spacing.sm) {
                        if let cost = item.estimatedCost {
                            Label {
                                Text(formattedCost(cost))
                                    .font(.caption)
                                    .foregroundStyle(.inkSecondary)
                            } icon: {
                                Image(systemName: "banknote")
                                    .font(.caption2)
                                    .foregroundStyle(.inkSecondary)
                            }
                        }

                        Label {
                            Text(timeRemaining(for: item))
                                .font(.caption)
                                .foregroundStyle(item.reminderDate > .now ? .inkSecondary : .stateWait)
                        } icon: {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundStyle(.inkSecondary)
                        }
                    }
                }

                Spacer()

                // Action buttons
                HStack(spacing: DS.Spacing.sm) {
                    Button {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7)) {
                            manager.resolveItem(id: item.id, didBuy: false)
                        }
                        HapticManager.success()
                        SoundManager.playIfEnabled(.success)
                    } label: {
                        Text("I passed")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.accentKept)
                            .padding(.horizontal, DS.Spacing.md)
                            .padding(.vertical, DS.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.sm)
                                    .fill(Color.accentKeptWash)
                            )
                    }
                    .buttonStyle(.scale)
                    .accessibilityLabel("I passed on \(item.name)")
                    .accessibilityHint("Double tap to mark as resisted")

                    Button {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7)) {
                            manager.resolveItem(id: item.id, didBuy: true)
                        }
                        HapticManager.warning()
                        SoundManager.playIfEnabled(.delete)
                    } label: {
                        Text("Bought")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.accentSpentText)
                            .padding(.horizontal, DS.Spacing.md)
                            .padding(.vertical, DS.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.sm)
                                    .fill(Color.accentSpentWash)
                            )
                    }
                    .buttonStyle(.scale)
                    .accessibilityLabel("Bought \(item.name)")
                    .accessibilityHint("Double tap to mark as purchased")
                }
            }
            .padding(DS.Spacing.lg)
        }
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .fill(Color.surfaceDial)
        )

        .pressable()
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
    }

    // MARK: - Resolved Section

    private var resolvedSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack(spacing: DS.Spacing.sm) {
                Image(systemName: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.inkSecondary)
                Text("Resolved")
                    .font(.headline)
                    .foregroundStyle(.inkSecondary)
            }

            ForEach(manager.resolvedItems.prefix(10)) { item in
                resolvedItemRow(item)
            }
        }
    }

    private func resolvedItemRow(_ item: WaitingItem) -> some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: item.didBuy == true ? "cart.fill" : "hand.raised.fill")
                .font(.caption)
                .foregroundStyle(item.didBuy == true ? .accentSpentText : .accentKept)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .foregroundStyle(.inkSecondary)
                    .strikethrough(item.didBuy == false, color: .inkSecondary)

                if let cost = item.estimatedCost, item.didBuy == false {
                    Text("Saved \(formattedCost(cost))")
                        .font(.caption2)
                        .foregroundStyle(.accentKept)
                }
            }

            Spacer()

            Text(item.didBuy == true
                ? "Bought"
                : "Resisted")
                .font(.caption2.weight(.medium))
                .foregroundStyle(item.didBuy == true ? .accentSpentText : .accentKept)
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.sm)
                .fill(Color.surfaceDial.opacity(0.6))
        )

    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        .accentKept.opacity(0.12)
                    )
                    .frame(width: 120, height: 120)
                Image(systemName: "clock.badge.checkmark")
                    .font(Font.adaptiveDisplay(size: 52, isRegular: isRegular))
                    .foregroundStyle(.accentKept.opacity(0.6))
                    .symbolEffect(.pulse, options: .repeating)
                    .accessibilityHidden(true)
            }

            VStack(spacing: DS.Spacing.sm) {
                Text("Your waiting list is empty")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.inkPrimary)

                Text("When you want to buy something, add it here.\nWe'll remind you when the waiting period is over.")
                    .font(.callout)
                    .foregroundStyle(.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
            }

            Button {
                HapticManager.tap()
                SoundManager.playIfEnabled(.tap)
                showAddForm = true
            } label: {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: "plus")
                        .font(.headline)
                    Text("Add Item")
                        .font(.headline)
                }
                .foregroundStyle(Color.inkOnAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.lg)
                        .fill(
                            .accentKept
                        )
                )

            }
            .buttonStyle(.scale)
            .padding(.horizontal, DS.Spacing.huge)

            Spacer()
        }
    }

    // MARK: - Add Item Sheet

    private var addItemSheet: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.xxl) {
                Spacer().frame(height: DS.Spacing.md)

                ZStack {
                    Circle()
                        .fill(
                            .accentKept.opacity(0.12)
                        )
                        .frame(width: 80, height: 80)
                    Image(systemName: "clock.badge.questionmark")
                        .font(Font.adaptiveDisplay(size: 36, isRegular: isRegular))
                        .foregroundStyle(.accentKept)
                        .accessibilityHidden(true)
                }

                VStack(spacing: DS.Spacing.lg) {
                    // Item name
                    TextField(
                        "What do you want to buy?",
                        text: $newItemName
                    )
                    .font(.body)
                    .padding(DS.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .fill(Color.surfaceDial)
                    )

                    // Estimated cost
                    TextField(
                        "Estimated price (optional)",
                        text: $newItemCost
                    )
                    .font(.body)
                    .keyboardType(.decimalPad)
                    .padding(DS.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.md)
                            .fill(Color.surfaceDial)
                    )

                    // Reminder duration
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        Text("When should we remind you?")
                            .font(.subheadline)
                            .foregroundStyle(.inkSecondary)

                        HStack(spacing: DS.Spacing.md) {
                            ForEach(reminderOptions, id: \.self) { hours in
                                Button {
                                    HapticManager.tap()
                                    selectedHours = hours
                                } label: {
                                    Text(reminderLabel(for: hours))
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(selectedHours == hours ? Color.inkOnAccent : .inkSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, DS.Spacing.md)
                                        .background(
                                            RoundedRectangle(cornerRadius: DS.Radius.md)
                                                .fill(selectedHours == hours
                                                    ? AnyShapeStyle(.accentKept)
                                                    : AnyShapeStyle(Color.surfaceDial))
                                        )

                                }
                                .buttonStyle(.scale)
                                .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: selectedHours)
                            }
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.xxl)

                Spacer()

                // Save button
                Button {
                    addItem()
                } label: {
                    Text("Add to Waiting List")
                        .font(.headline)
                        .foregroundStyle(Color.inkOnAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.lg)
                                .fill(newItemName.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? AnyShapeStyle(Color.accentKept.opacity(0.4))
                                    : AnyShapeStyle(.accentKept))
                        )

                }
                .buttonStyle(.scale)
                .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, DS.Spacing.xxl)
                .padding(.bottom, DS.Spacing.xxxl)
            }
            .background(Color.surfaceField)
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.tap()
                        showAddForm = false
                    }
                    .accessibilityIdentifier("add_item_cancel")
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Helpers

    private func addItem() {
        let name = newItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let cost = Double(newItemCost.replacingOccurrences(of: ",", with: "."))
        let item = WaitingItem(name: name, estimatedCost: cost, reminderHours: selectedHours)
        manager.addItem(item)

        HapticManager.save()
        SoundManager.playIfEnabled(.save)
        newItemName = ""
        newItemCost = ""
        selectedHours = 24
        showAddForm = false
    }

    private func formattedCost(_ cost: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: cost)) ?? "$\(Int(cost))"
    }

    private func timeRemaining(for item: WaitingItem) -> String {
        let remaining = item.reminderDate.timeIntervalSinceNow
        if remaining <= 0 {
            return "Time's up"
        }
        let hours = Int(remaining / 3600)
        if hours >= 24 {
            let days = hours / 24
            return "\(days) days left"
        }
        return "\(hours) hours left"
    }

    private func reminderLabel(for hours: Int) -> String {
        switch hours {
        case 24: "24 hours"
        case 48: "48 hours"
        case 72: "72 hours"
        default: "\(hours) hours"
        }
    }
}

#Preview {
    WaitingListSheet()
        .environment(StoreService.shared)
}
