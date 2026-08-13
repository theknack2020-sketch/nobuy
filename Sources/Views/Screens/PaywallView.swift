import StoreKit
import SwiftData
import SwiftUI

/// Why the paywall opened.
///
/// Owner law 2026-08-07: listing what Pro GIVES is only half the offer — when a limit sent the
/// user here, the sheet must name THAT limit in the user's own numbers. Declared inside this
/// file on purpose: a fix whose remedy is a new file under `Sources/` is a scope change, and the
/// measured cost of that pattern (Caliper v1.1) was every finding of two later review rounds.
enum PaywallEntry: Equatable {
    /// The user tried to add an essential category beyond the free allowance.
    case categoryLimit(used: Int, limit: Int)
    /// The user reached back past the free window.
    case recordWindow(held: Int, window: Int)
    /// Every free waiting slot is in use.
    case waitingSlots(used: Int, limit: Int)
    /// Pro-only surfaces, named so the sheet can say what was reached for.
    case challenges
    case themes
    case analysis
    case weeklySummary
    /// Opened deliberately from Settings or a milestone — no limit was hit.
    case general

    /// The headline over the standing slot.
    func title(held: Int, window: Int) -> String {
        switch self {
        case .recordWindow: "The record outgrew the free window."
        case .categoryLimit: "Every essential you track."
        case .waitingSlots: "Room for everything you're waiting on."
        case .challenges: "Set your own runs."
        case .themes: "Five finishes."
        case .analysis, .weeklySummary: "The pattern behind the run."
        case .general: "Where you stand."
        }
    }

    /// The standing line: where the user is, in their own numbers. This slot is FIXED — it
    /// renders in every state, carrying the neutral form when no limit was hit, because a slot
    /// that appears only on failure teaches the user that the sheet is a punishment.
    func standingLine(held: Int, window: Int, firstDay: String?) -> String {
        switch self {
        case let .recordWindow(held, window):
            if let firstDay {
                return "You turned the record back past \(window) days. Yours holds \(dayCount(held)), to \(firstDay)."
            }
            return "You turned the record back past \(window) days. Yours holds \(dayCount(held))."
        case let .categoryLimit(used, limit):
            return "You're using \(used) of \(limit) free essential categories."
        case let .waitingSlots(used, limit):
            return "All \(used) of your \(limit) free waiting slots are in use."
        case .challenges:
            return "Your record holds \(dayCount(held)). Challenges run on top of it."
        case .themes:
            return "One dial finish is free. Four more come with Pro."
        case .analysis, .weeklySummary:
            return "Your record holds \(dayCount(held)). Pro reads the pattern in them."
        case .general:
            return "Your record holds \(dayCount(held)). The free window shows the latest \(window)."
        }
    }
}

// MARK: - Paywall — the door, in five states
//
// A sheet, never a room (`screens/paywall.dc.html`). Held to a HIGHER bar than the hero screen
// by owner law 2026-08-07, which this file tries to earn rather than merely satisfy:
//
//   · the standing slot is fixed and first — the limit named in the user's own numbers, drawn
//     on the record gauge in the same silvered geometry as the rest of the product;
//   · the generous truth sits ABOVE the price, and the full free list is one tap away;
//   · both plans are equally visible — no pre-selected annual dressed as the only option;
//   · the trial sentence is complete: length → what it becomes → how to stop it;
//   · prices are never typed, so the sheet owns an honest LOADING and ERROR state;
//   · dismissal is immediate and named "Not now".
//
// Banned and absent: comparison grid, lock or crown imagery, countdown, strikethrough against a
// price that never existed, and any wording that implies a feature exists when it does not.

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.openURL) private var openURL
    @Query(sort: \DayRecord.date, order: .forward) private var records: [DayRecord]

    let store: StoreService
    var entry: PaywallEntry = .general

    @State private var selectedPlan: StoreService.Plan = .yearly
    @State private var showFreeList = false
    @State private var gaugeDrawn = false

    /// The gauge's count is read, not engraved — it scales, with a floor that keeps it the
    /// largest thing on the sheet.
    @ScaledMetric(relativeTo: .title) private var scaledGaugeCount: CGFloat = 34

    private var isRegular: Bool { sizeClass == .regular }

    private var isPurchasing: Bool {
        if case .purchasing = store.purchaseState { return true }
        return false
    }

    // MARK: - The user's own numbers

    private var daysHeld: Int { records.count }
    private var freeWindow: Int { StoreService.freeRecordWindowDays }
    private var firstDayText: String? {
        records.first.map { Self.shortDate.string(from: $0.date) }
    }

    /// The fraction of the record the free window covers. The gauge draws this as its first
    /// arc and the remainder as its second — the whole offer, in one object.
    private var freeFraction: Double {
        guard daysHeld > 0 else { return 1 }
        return min(Double(freeWindow) / Double(daysHeld), 1)
    }

    private var daysBeyondWindow: Int { max(daysHeld - freeWindow, 0) }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: DS.Spacing.xxl) {
                    recordGauge
                    header
                    generousNotice
                    valueSection

                    if store.isPro {
                        alreadyProNotice
                    } else if store.isLoadingProducts, store.products.isEmpty {
                        loadingPrices
                    } else if store.loadFailed {
                        loadFailure
                    } else {
                        planPicker
                        purchaseButton
                        trialSentence
                    }

                    footerLinks
                }
                .padding(.horizontal, DS.Spacing.screenGutter)
                .padding(.vertical, DS.Spacing.xxl)
                .frame(maxWidth: isRegular ? 600 : .infinity, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(Color.surfaceField)
            .navigationTitle("NoBuy Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Named, immediate, and the second element on the sheet. A delayed or disguised
                // dismiss is banned: a product that needs a trapped user is selling something
                // too weak to sell itself.
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") {
                        store.notePaywallDismissed()
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.inkSecondary)
                    .disabled(isPurchasing)
                    .accessibilityIdentifier("paywall_close")
                }
            }
            .sheet(isPresented: $showFreeList) { freeTierSheet }
            .task { await onAppearSetup() }
            .onChange(of: store.purchaseState) { _, newValue in
                if case .purchased = newValue { dismiss() }
            }
        }
    }

    // MARK: - The record gauge
    //
    // The limit drawn on the product's own geometry: one bezel, two arcs. The first arc is the
    // free window, the second is what Pro opens — so the offer is a PLACE on the user's record
    // rather than a threat. The count at the centre is theirs, not ours.

    private var recordGauge: some View {
        VStack(spacing: DS.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.surfaceDial)
                    .frame(width: 104 - 4, height: 104 - 4)

                BezelDial(size: 104, scale: .interval)

                // Arc 2 (drawn first, so the free arc sits on top of it): the whole record.
                SweepArc(size: 104, progress: gaugeDrawn ? 1 : 0, color: .stateWait)
                // Arc 1: the part the free window covers.
                SweepArc(size: 104, progress: gaugeDrawn ? freeFraction : 0, color: .accentKept)

                VStack(spacing: 0) {
                    Text("\(daysHeld)")
                        .font(.system(size: max(scaledGaugeCount, 34), weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(.inkPrimary)
                    // Engraved on a 104pt face, so it is sized like a dial numeral rather than
                    // like reading text: `caption2` plus a max width clipped to "ays on recor"
                    // on the first build. What a user reads here is the COUNT; this line labels
                    // it, and the same words are spoken in full by VoiceOver above.
                    Text(daysHeld == 1 ? "day on record" : "days on record")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundStyle(.inkSecondary)
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Your record holds \(dayCount(daysHeld)). The free window shows the latest \(min(freeWindow, daysHeld)).")

            HStack(spacing: DS.Spacing.lg) {
                if daysHeld == 0 {
                    Text("Your record starts tonight.")
                        .font(.caption2)
                        .foregroundStyle(.inkSecondary)
                } else {
                    gaugeKey(color: .accentKept, text: "the latest \(min(freeWindow, daysHeld)) — free, always")
                    if daysBeyondWindow > 0 {
                        gaugeKey(color: .stateWait, text: "\(daysBeyondWindow) more, kept for Pro")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .accessibilityHidden(true)
        }
    }

    private func gaugeKey(color: Color, text: String) -> some View {
        HStack(spacing: DS.Spacing.xs) {
            Capsule().fill(color).frame(width: 12, height: DS.Stroke.tickMajor)
            Text(text)
                .font(.caption2)
                .foregroundStyle(.inkSecondary)
        }
    }

    // MARK: - Header — the standing slot, fixed and first

    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text(entry.title(held: daysHeld, window: freeWindow))
                .font(.title2.weight(.bold))
                .foregroundStyle(.inkPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(entry.standingLine(held: daysHeld, window: freeWindow, firstDay: firstDayText))
                .font(.subheadline)
                .foregroundStyle(.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("paywall_entry_context")
        }
    }

    /// The generous truth, above the price. It is the half of the offer that costs nothing to
    /// tell and is the reason the sheet can be honest about the half that does.
    private var generousNotice: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text(L10n.paywallGenerous)
                .font(.subheadline)
                .foregroundStyle(.inkPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                showFreeList = true
            } label: {
                HStack(spacing: 2) {
                    Text(L10n.paywallFreeListLink)
                    Image(systemName: "chevron.right").font(.caption2)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.accentKept)
            }
            .accessibilityIdentifier("paywall_free_list")
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.sheet)
                .fill(Color.surfaceWell)
        )
    }

    // MARK: - What Pro adds

    private struct ProBenefit: Identifiable {
        let id = UUID()
        let title: String
    }

    /// Every line maps 1:1 to a shipped `isPro` gate. A promise with no gate is deleted, not
    /// shipped — the v1 sheet advertised a 16-row grid, one row of which had no code behind it.
    private var benefits: [ProBenefit] {
        [
            ProBenefit(title: "Every day on record, back to the first"),
            ProBenefit(title: "The analysis: monthly trend, weekday pattern, streak history"),
            ProBenefit(title: "Challenges you set yourself"),
            ProBenefit(title: "Unlimited essentials and freezes"),
            ProBenefit(title: "An open waiting list — free holds \(StoreService.freeWaitingSlots)"),
            ProBenefit(title: "Five dial finishes"),
        ]
    }

    private var valueSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            ForEach(benefits) { benefit in
                HStack(alignment: .top, spacing: DS.Spacing.md) {
                    // A tick from the product's own vocabulary — the same mark a kept day
                    // carries. Not a checkmark: this sheet has no ✓/✗ grammar anywhere.
                    DayMark(truth: .kept)
                        .padding(.top, 2)
                        .accessibilityHidden(true)

                    Text(benefit.title)
                        .font(.subheadline)
                        .foregroundStyle(.inkPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Plans

    private var planPicker: some View {
        VStack(spacing: DS.Spacing.md) {
            ForEach([StoreService.Plan.yearly, .monthly], id: \.self) { plan in
                planRow(plan)
            }
        }
    }

    private func planRow(_ plan: StoreService.Plan) -> some View {
        let isSelected = selectedPlan == plan
        let price = store.displayPrice(for: plan) ?? ""
        let cadence = plan == .monthly ? "month" : "year"
        let title = plan == .monthly ? "Monthly" : "Yearly"

        return Button {
            HapticManager.toggle()
            withAnimation(reduceMotion ? nil : DS.Anim.functional) { selectedPlan = plan }
        } label: {
            HStack(spacing: DS.Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.inkPrimary)

                    Text("\(price) / \(cadence)")
                        .font(.subheadline)
                        .foregroundStyle(.inkSecondary)

                    if store.trialTerms(for: plan) != nil {
                        Text("first 7 days free")
                            .font(.caption)
                            .foregroundStyle(.accentKept)
                    }
                }

                Spacer(minLength: 0)

                if plan == .yearly, let saving = store.yearlySavingsPercent {
                    Text("Save \(saving)%")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.inkSecondary)
                }
            }
            .padding(DS.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.sheet)
                    .fill(Color.surfaceDial)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.sheet)
                            .strokeBorder(
                                isSelected ? Color.accentKept : Color.inkHairline,
                                lineWidth: isSelected ? 2 : DS.Stroke.hairline
                            )
                    )
            )
        }
        .buttonStyle(.scale)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(price) per \(cadence)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("paywall_plan_\(plan == .monthly ? "monthly" : "yearly")")
    }

    private var purchaseButton: some View {
        VStack(spacing: DS.Spacing.sm) {
            Button {
                Task { await store.purchase(selectedPlan) }
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView().tint(Color.inkOnAccent)
                    } else {
                        Text(store.trialTerms(for: selectedPlan) == nil ? "Subscribe" : "Start 7 days free")
                            .font(.headline)
                    }
                }
                .foregroundStyle(Color.inkOnAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Capsule().fill(Color.accentKept))
            }
            .buttonStyle(.scale)
            .disabled(isPurchasing)
            .accessibilityIdentifier("paywall_purchase_button")

            if case .pending = store.purchaseState {
                Text("Waiting for approval. Access arrives as soon as it's approved.")
                    .font(.footnote)
                    .foregroundStyle(.inkSecondary)
                    .multilineTextAlignment(.center)
            }

            if case let .failed(message) = store.purchaseState {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.accentSpentText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// The whole trial sentence, rewritten whenever a plan is selected: how long it is free,
    /// what it becomes, at what price, and exactly how to stop it.
    private var trialSentence: some View {
        Group {
            if let terms = store.trialTerms(for: selectedPlan) {
                Text(terms)
            } else if let price = store.displayPrice(for: selectedPlan) {
                Text("\(price) per \(selectedPlan == .monthly ? "month" : "year"). Cancel any time in Settings ▸ Subscriptions.")
            }
        }
        .font(.footnote)
        .foregroundStyle(.inkSecondary)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("paywall_trial_terms")
    }

    // MARK: - Non-selling states

    private var alreadyProNotice: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text(L10n.paywallWelcome)
                .font(.headline)
                .foregroundStyle(.inkPrimary)
            Text(store.isLegacyLifetimeOwner ? L10n.paywallLegacyOwner : L10n.paywallWelcomeDetail)
                .font(.subheadline)
                .foregroundStyle(.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.lg)
        .background(RoundedRectangle(cornerRadius: DS.Radius.sheet).fill(Color.accentKeptWash))
    }

    /// Honest loading: the prices come from the App Store, so the sheet says so and promises
    /// nothing while it waits.
    private var loadingPrices: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack(spacing: DS.Spacing.md) {
                ProgressView()
                Text("Fetching prices from the App Store")
                    .font(.subheadline)
                    .foregroundStyle(.inkSecondary)
            }
            Text("The trial terms appear with the price. Nothing is charged on this screen.")
                .font(.footnote)
                .foregroundStyle(.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var loadFailure: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("The App Store didn't answer.")
                .font(.headline)
                .foregroundStyle(.inkPrimary)
            Text("Prices and trial terms come from Apple, and we won't guess them. Everything you've logged is still here.")
                .font(.footnote)
                .foregroundStyle(.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("Try again") {
                Task { await store.loadProducts() }
            }
            .font(.headline)
            .foregroundStyle(.accentKept)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Capsule().fill(Color.surfaceDial))
            .accessibilityIdentifier("paywall_retry")
        }
    }

    // MARK: - Free tier — one tap away, never a grid

    private var freeTierSheet: some View {
        NavigationStack {
            List {
                Section {
                    freeRow("The nightly question, the answer, and your run")
                    freeRow("The last \(freeWindow) days of the record, on every surface")
                    freeRow("One streak freeze each month")
                    freeRow("The 10-minute urge timer and the impulse checklist")
                    freeRow("The waiting list, up to \(StoreService.freeWaitingSlots) items held at once")
                    freeRow("Three essential categories")
                    freeRow("All achievements")
                    freeRow("Every widget — Home and Lock Screen, including the one-tap answer")
                    freeRow("CSV export and erase — your data is never held hostage")
                } header: {
                    Text(L10n.paywallFreeListTitle)
                } footer: {
                    Text("No account, no bank connection, nothing leaves your device — on any plan.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceField)
            .navigationTitle(L10n.paywallFreeListTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showFreeList = false }
                }
            }
        }
    }

    private func freeRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.md) {
            DayMark(truth: .kept)
                .padding(.top, 2)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.inkPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Footer

    private var footerLinks: some View {
        VStack(spacing: DS.Spacing.md) {
            HStack(spacing: DS.Spacing.xl) {
                Button(L10n.paywallRestore) {
                    Task { await store.restore() }
                }
                .accessibilityIdentifier("paywall_restore")

                Button("Terms") { open(L10n.AppLinks.terms) }
                Button("Privacy") { open(L10n.AppLinks.privacy) }
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.inkSecondary)

            if store.restoreState == .success {
                Text(L10n.paywallRestoreSuccess)
                    .font(.caption)
                    .foregroundStyle(.accentKept)
            } else if store.restoreState == .failed {
                Text(L10n.paywallRestoreFail)
                    .font(.caption)
                    .foregroundStyle(.inkSecondary)
            }

            Text("Prices are set by the App Store · © 2026 TheKnack")
                .font(.caption2)
                .foregroundStyle(.inkSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        openURL(url)
    }

    // MARK: - Lifecycle

    private func onAppearSetup() async {
        store.notePaywallShown()
        if store.products.isEmpty { await store.loadProducts() }
        if store.products[.yearly] == nil, store.products[.monthly] != nil {
            selectedPlan = .monthly
        }
        // The gauge draws its two arcs once, 240ms. Reduce Motion gets them pre-drawn rather
        // than a still frame of nothing.
        if reduceMotion {
            gaugeDrawn = true
        } else {
            withAnimation(DS.Anim.gauge) { gaugeDrawn = true }
        }
    }

    private static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "d MMMM"
        return f
    }()
}

/// "1 day", not "1 days". Every number this screen prints is the reader's OWN number, quoted
/// back at them while they decide whether to pay; a grammar slip there reads as carelessness
/// about the record itself.
func dayCount(_ n: Int) -> String { "\(n) " + (n == 1 ? "day" : "days") }
