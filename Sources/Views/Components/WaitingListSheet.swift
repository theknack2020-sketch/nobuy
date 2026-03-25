import SwiftUI

struct WaitingListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(StoreService.self) private var store

    private var manager = WaitingListManager.shared

    @State private var showAddForm = false
    @State private var showPaywall = false
    @State private var newItemName = ""
    @State private var newItemCost = ""
    @State private var selectedHours = 24
    @State private var appeared = false

    private let reminderOptions = [24, 48, 72]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePrimary.ignoresSafeArea()

                if manager.activeItems.isEmpty && manager.resolvedItems.isEmpty {
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
                    HStack(spacing: DS.Spacing.xs) {
                        if !store.isPro && manager.activeItems.count >= 3 {
                            Text("PRO")
                                .font(.caption2.bold())
                                .foregroundStyle(.noBuyGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.noBuyGreenLight))
                        }
                        Button {
                            if !store.isPro && manager.activeItems.count >= 3 {
                                showPaywall = true
                            } else {
                                HapticManager.tap()
                                SoundManager.playIfEnabled(.tap)
                                showAddForm = true
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(!store.isPro && manager.activeItems.count >= 3 ? .textTertiary : .noBuyGreen)
                        }
                        .buttonStyle(.scale)
                        .accessibilityLabel(!store.isPro && manager.activeItems.count >= 3 ? "Upgrade to Pro for unlimited items" : "Add new item to waiting list")
                        .accessibilityIdentifier("waiting_list_add")
                    }
                }
            }
            .sheet(isPresented: $showAddForm) {
                addItemSheet
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(store: store)
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
                        RadialGradient(
                            colors: [.noBuyGreen.opacity(0.2), .noBuyGreen.opacity(0.05)],
                            center: .center,
                            startRadius: 2,
                            endRadius: 22
                        )
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: "leaf.fill")
                    .font(.title3)
                    .foregroundStyle(.noBuyGreen)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("Saved by not buying")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                Text(formattedSavedMoney)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.noBuyGreen, .green.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            Spacer()
        }
        .padding(DS.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.lg)
                .fill(Color.noBuyGreen.opacity(0.08))
        )
        .shadow(color: .noBuyGreen.opacity(0.1), radius: 6, x: 0, y: 3)
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
                Image(systemName: "clock.fill")
                    .font(.subheadline)
                    .foregroundStyle(.noBuyGreen)
                Text("Waiting")
                    .font(.headline)
                    .foregroundStyle(.textPrimary)
                Spacer()
                Text("\(manager.activeItems.count)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.noBuyGreen)
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(Capsule().fill(Color.noBuyGreenLight))
            }

            ForEach(manager.activeItems) { item in
                activeItemRow(item)
            }

            // Free user limit indicator
            if !store.isPro {
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: manager.activeItems.count >= 3 ? "lock.fill" : "info.circle")
                        .font(.caption)
                        .foregroundStyle(manager.activeItems.count >= 3 ? .mandatoryAmber : .textTertiary)
                    Text(manager.activeItems.count >= 3
                         ? "Free limit reached (3/3). Upgrade to Pro for unlimited items."
                         : "\(manager.activeItems.count)/3 free slots used")
                        .font(.caption)
                        .foregroundStyle(manager.activeItems.count >= 3 ? .mandatoryAmber : .textTertiary)
                    Spacer()
                    if manager.activeItems.count >= 3 {
                        Button {
                            showPaywall = true
                        } label: {
                            Text("PRO")
                                .font(.caption2.bold())
                                .foregroundStyle(.noBuyGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.noBuyGreenLight))
                        }
                        .buttonStyle(.scale)
                    }
                }
                .padding(.horizontal, DS.Spacing.sm)
                .padding(.vertical, DS.Spacing.xs)
            }
        }
    }

    private func activeItemRow(_ item: WaitingItem) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: DS.Spacing.md) {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.textPrimary)

                    HStack(spacing: DS.Spacing.sm) {
                        if let cost = item.estimatedCost {
                            Label {
                                Text(formattedCost(cost))
                                    .font(.caption)
                                    .foregroundStyle(.textSecondary)
                            } icon: {
                                Image(systemName: "turkishlirasign")
                                    .font(.caption2)
                                    .foregroundStyle(.textTertiary)
                            }
                        }

                        Label {
                            Text(timeRemaining(for: item))
                                .font(.caption)
                                .foregroundStyle(item.reminderDate > .now ? .textSecondary : .mandatoryAmber)
                        } icon: {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundStyle(.textTertiary)
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
                            .foregroundStyle(.noBuyGreen)
                            .padding(.horizontal, DS.Spacing.md)
                            .padding(.vertical, DS.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.sm)
                                    .fill(Color.noBuyGreenLight)
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
                            .foregroundStyle(.spendRed)
                            .padding(.horizontal, DS.Spacing.md)
                            .padding(.vertical, DS.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.sm)
                                    .fill(Color.spendRedLight)
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
                .fill(Color.surfaceSecondary)
        )
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
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
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.textTertiary)
                Text("Resolved")
                    .font(.headline)
                    .foregroundStyle(.textSecondary)
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
                .foregroundStyle(item.didBuy == true ? .spendRed : .noBuyGreen)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                    .strikethrough(item.didBuy == false, color: .textTertiary)

                if let cost = item.estimatedCost, item.didBuy == false {
                    Text("Saved \(formattedCost(cost))")
                        .font(.caption2)
                        .foregroundStyle(.noBuyGreen)
                }
            }

            Spacer()

            Text(item.didBuy == true
                 ? "Bought"
                 : "Resisted")
                .font(.caption2.weight(.medium))
                .foregroundStyle(item.didBuy == true ? .spendRed : .noBuyGreen)
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.sm)
                .fill(Color.surfaceSecondary.opacity(0.6))
        )
        .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.noBuyGreen.opacity(0.15), .noBuyGreen.opacity(0.02)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 52))
                    .foregroundStyle(.noBuyGreen.opacity(0.6))
                    .symbolEffect(.pulse, options: .repeating)
                    .accessibilityHidden(true)
            }

            VStack(spacing: DS.Spacing.sm) {
                Text("Your waiting list is empty")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.textPrimary)

                Text("When you want to buy something, add it here.\nWe'll remind you when the waiting period is over.")
                    .font(.callout)
                    .foregroundStyle(.textSecondary)
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
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.lg)
                        .fill(
                            LinearGradient(
                                colors: [.noBuyGreen, .noBuyGreen.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: .noBuyGreen.opacity(0.3), radius: 10, x: 0, y: 5)
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
                            RadialGradient(
                                colors: [.noBuyGreen.opacity(0.2), .noBuyGreen.opacity(0.03)],
                                center: .center,
                                startRadius: 5,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 36))
                        .foregroundStyle(.noBuyGreen)
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
                            .fill(Color.surfaceSecondary)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 2)

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
                            .fill(Color.surfaceSecondary)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 2)

                    // Reminder duration
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        Text("When should we remind you?")
                            .font(.subheadline)
                            .foregroundStyle(.textSecondary)

                        HStack(spacing: DS.Spacing.md) {
                            ForEach(reminderOptions, id: \.self) { hours in
                                Button {
                                    HapticManager.tap()
                                    selectedHours = hours
                                } label: {
                                    Text(reminderLabel(for: hours))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(selectedHours == hours ? .white : .textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DS.Spacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: DS.Radius.md)
                                            .fill(selectedHours == hours
                                                ? AnyShapeStyle(LinearGradient(colors: [.noBuyGreen, .noBuyGreen.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                                                : AnyShapeStyle(Color.surfaceSecondary))
                                    )
                                    .shadow(color: selectedHours == hours ? .noBuyGreen.opacity(0.2) : .black.opacity(0.04), radius: 4, x: 0, y: 2)
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
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.lg)
                                .fill(newItemName.trimmingCharacters(in: .whitespaces).isEmpty
                                      ? AnyShapeStyle(Color.noBuyGreen.opacity(0.4))
                                      : AnyShapeStyle(LinearGradient(colors: [.noBuyGreen, .noBuyGreen.opacity(0.8)], startPoint: .leading, endPoint: .trailing)))
                        )
                        .shadow(color: newItemName.trimmingCharacters(in: .whitespaces).isEmpty ? .clear : .noBuyGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.scale)
                .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, DS.Spacing.xxl)
                .padding(.bottom, DS.Spacing.xxxl)
            }
            .background(Color.surfacePrimary)
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
        case 24: return "24 hours"
        case 48: return "48 hours"
        case 72: return "72 hours"
        default: return "\(hours) hours"
        }
    }
}

#Preview {
    WaitingListSheet()
        .environment(StoreService.shared)
}
