import Foundation
import Observation
import os
import StoreKit

@Observable
@MainActor
final class StoreService {
    static let shared = StoreService()

    // MARK: - Product identity

    /// The two auto-renewable plans sold from v2.0.0 onwards.
    enum Plan: String, CaseIterable, Sendable {
        case monthly = "com.ufukozdemir.nobuy.monthly"
        case yearly = "com.ufukozdemir.nobuy.yearly"
    }

    /// The one-time unlock sold between 2026-03 and 2026-08 to 60 customers.
    ///
    /// It is REMOVED FROM SALE, never deleted. Everyone who bought it keeps every Pro feature
    /// permanently: the app checks this product id on every entitlement pass and treats it as a
    /// standing grant. Deleting the product — or dropping this check — would silently downgrade
    /// paying customers, which is both a 1-star event and a support liability. The id also stays
    /// in `NoBuy.storekit` so the inherited path is testable in the simulator.
    nonisolated static let legacyLifetimeProductID = "com.ufukozdemir.nobuy.pro"

    // MARK: - Entitlement state

    /// True when the user may use every Pro feature — by subscription OR by legacy purchase.
    private(set) var isPro = false

    /// True when Pro comes from the retired one-time unlock. Drives the Settings row that tells
    /// these 60 customers, in plain words, that their purchase still stands and always will.
    /// They are never shown the paywall.
    private(set) var isLegacyLifetimeOwner = false

    /// True when Pro comes from a live auto-renewable subscription.
    private(set) var hasActiveSubscription = false

    /// Loaded plans, keyed by `Plan`. Prices ALWAYS render from here — never typed into a view.
    private(set) var products: [Plan: Product] = [:]

    /// Set when product loading failed, so the paywall can offer a retry instead of an empty box.
    private(set) var loadFailed = false
    private(set) var isLoadingProducts = false

    var purchaseState: PurchaseState = .idle
    private(set) var restoreState: RestoreState = .idle

    // MARK: - Free-tier caps
    //
    // The map lives in `.design/rounds/r2/docs/FREE-TIER.md`; these are its numbers. Every one
    // of them is named on the paywall in the user's OWN figures when it is what sent them there
    // (owner law 2026-08-07), which is why they are constants rather than magic numbers spread
    // across the screens that enforce them.
    //
    // What free deliberately keeps, and the paywall says so above the price: the nightly
    // question, the run, the freeze, both interventions, CSV export, erase, and the entire
    // widget family. Pro sells DEPTH of the same record — never the record itself, and never
    // the path to it.

    /// Essential categories a free account may keep.
    nonisolated static let freeCategoryLimit = 3

    /// How far back the record opens without Pro. The data is never deleted or expired — only
    /// the in-app view is windowed, and CSV export (free) always carries everything.
    nonisolated static let freeRecordWindowDays = 90

    /// Items that may sit on the waiting list at once.
    nonisolated static let freeWaitingSlots = 3

    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case purchased
        /// Ask to Buy / deferred approval — not a cancel, not a failure.
        case pending
        case failed(String)
    }

    enum RestoreState: Equatable {
        case idle
        case success
        case failed
    }

    // MARK: - Paywall Frequency Cap (local-only UserDefaults state)

    @ObservationIgnored
    private let paywallShownCountKey = "paywallShownCount"
    @ObservationIgnored
    private let paywallLastShownDateKey = "paywallLastShownDate"
    @ObservationIgnored
    private let paywallLastDismissDateKey = "paywallLastDismissDate"

    var paywallShownCount: Int {
        get { UserDefaults.standard.integer(forKey: paywallShownCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: paywallShownCountKey) }
    }

    var paywallLastShownDate: Date? {
        get { UserDefaults.standard.object(forKey: paywallLastShownDateKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: paywallLastShownDateKey) }
    }

    private var paywallLastDismissDate: Date? {
        get { UserDefaults.standard.object(forKey: paywallLastDismissDateKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: paywallLastDismissDateKey) }
    }

    /// Track that the paywall was displayed
    func notePaywallShown() {
        paywallShownCount += 1
        paywallLastShownDate = .now
    }

    /// Track that the paywall was dismissed without purchase
    func notePaywallDismissed() {
        paywallLastDismissDate = .now
    }

    /// Don't show paywall within 24h of last dismiss, unless the user hit a milestone
    func canShowPaywall(atMilestone: Bool = false) -> Bool {
        if isPro { return false }
        if atMilestone { return true }
        guard let lastDismiss = paywallLastDismissDate else { return true }
        return Date.now.timeIntervalSince(lastDismiss) > 86400 // 24 hours
    }

    // MARK: - Prices (always store-sourced)

    func product(for plan: Plan) -> Product? { products[plan] }

    func displayPrice(for plan: Plan) -> String? { products[plan]?.displayPrice }

    /// Kept for the surfaces that show a single entry price; resolves to the monthly plan.
    var formattedPrice: String? { displayPrice(for: .monthly) }

    /// How much cheaper a year of the yearly plan is than twelve monthly renewals, rounded down.
    /// Returns nil unless BOTH plans loaded — a saving claim we cannot compute is one we do not make.
    var yearlySavingsPercent: Int? {
        guard let monthly = products[.monthly]?.price,
              let yearly = products[.yearly]?.price
        else { return nil }
        let twelveMonths = monthly * 12
        guard twelveMonths > 0, yearly < twelveMonths else { return nil }
        let saved = (twelveMonths - yearly) / twelveMonths * 100
        return Int(NSDecimalNumber(decimal: saved).doubleValue.rounded(.down))
    }

    /// The full trial sentence, assembled from what the store actually offers: how long it is
    /// free, what it becomes, at what price, and how to stop it. Nil when the plan carries no
    /// free-trial offer, so no view can promise a trial that does not exist.
    func trialTerms(for plan: Plan) -> String? {
        guard let product = products[plan],
              let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial
        else { return nil }
        let cadence = plan == .monthly ? "month" : "year"
        let length = Self.describe(offer.period)
        // The verbatim pattern from `docs/HANDOFF.md`. Every clause earns its place: how long
        // it is free, what it becomes, at what price, where to stop it, and — the one most
        // paywalls leave out — what happens if you do stop it in time.
        return "\(length) free, then \(product.displayPrice) a \(cadence). "
            + "Cancel any time in Settings ▸ Subscriptions before the trial ends and nothing is charged."
    }

    /// Human wording for a trial's length.
    ///
    /// Weeks are stated in DAYS ("7 days", not "1 week"): the offer Apple carries is ONE_WEEK,
    /// and seven days is the same span said in the unit a person counts in. Months and years
    /// keep their own unit, where a day count would be the vaguer claim.
    private static func describe(_ period: Product.SubscriptionPeriod) -> String {
        let n = period.value
        switch period.unit {
        case .day: return n == 1 ? "1 day" : "\(n) days"
        case .week: return n * 7 == 1 ? "1 day" : "\(n * 7) days"
        case .month: return n == 1 ? "1 month" : "\(n) months"
        case .year: return n == 1 ? "1 year" : "\(n) years"
        @unknown default: return "\(n) periods"
        }
    }

    private init() {}

    // MARK: - Gates

    func canAddCategory(currentCount: Int) -> Bool {
        isPro || currentCount < Self.freeCategoryLimit
    }

    func remainingFreeSlots(currentCount: Int) -> Int {
        isPro ? .max : max(Self.freeCategoryLimit - currentCount, 0)
    }

    /// Challenges require Pro
    var canStartChallenge: Bool {
        isPro
    }

    /// The oldest date the record opens to without Pro. Nil for Pro (and for legacy owners):
    /// the record opens to the first day.
    func recordWindowStart(now: Date = .now, calendar: Calendar = .current) -> Date? {
        guard !isPro else { return nil }
        let today = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: -(Self.freeRecordWindowDays - 1), to: today)
    }

    /// Whether a date is inside the free window (always true on Pro).
    func canOpenRecord(on date: Date, now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard let start = recordWindowStart(now: now, calendar: calendar) else { return true }
        return calendar.startOfDay(for: date) >= start
    }

    /// Whether another item may be parked on the waiting list.
    func canHoldAnotherItem(currentCount: Int) -> Bool {
        isPro || currentCount < Self.freeWaitingSlots
    }

    /// Soft paywall banner shown count (read-only convenience)
    var softPaywallShownCount: Int {
        UserDefaults.standard.integer(forKey: "softPaywallShownCount")
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: Plan.allCases.map(\.rawValue))
            var byPlan: [Plan: Product] = [:]
            for product in loaded {
                if let plan = Plan(rawValue: product.id) { byPlan[plan] = product }
            }
            products = byPlan
            // A partial load is a failed load: a paywall that can only offer one of two plans
            // silently removes the user's choice, which is the pre-selected-annual pattern the
            // design law bans — just arrived at by accident instead of on purpose.
            loadFailed = byPlan.count != Plan.allCases.count
            if loadFailed {
                AppLogger.store.warning("Loaded \(byPlan.count) of \(Plan.allCases.count) plans")
            }
        } catch {
            AppLogger.store.error("Failed to load products: \(error.localizedDescription)")
            loadFailed = true
        }
    }

    // MARK: - Purchase

    func purchase(_ plan: Plan) async {
        guard let product = products[plan] else {
            purchaseState = .failed(L10n.purchaseErrorGeneric)
            return
        }
        purchaseState = .purchasing

        do {
            let result = try await product.purchase()
            switch result {
            case let .success(verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                // Re-derive from the source of truth rather than assuming this purchase is the
                // whole picture — the user may also hold the legacy grant.
                await checkEntitlements()
                purchaseState = .purchased
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .pending
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(mapError(error))
        }
    }

    // MARK: - Restore

    func restore() async {
        restoreState = .idle
        do {
            try await AppStore.sync()
            await checkEntitlements()
            restoreState = isPro ? .success : .failed
        } catch {
            restoreState = .failed
            AppLogger.store.error("Restore failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Entitlements

    #if DEBUG
        /// Store-shots demo runs force Pro so panels show unlocked value
        /// without waiting on a StoreKit product load.
        func forceProForDemo() {
            isPro = true
        }
    #endif

    /// Single source of truth for Pro access. Walks EVERY current entitlement rather than
    /// returning on the first match, because the two grants are not mutually exclusive: a legacy
    /// owner can also start a subscription, and we must know both to show the right Settings row.
    func checkEntitlements() async {
        // Screenshot runs show Pro value unlocked — never the price wall.
        if DemoMode.isActive {
            isPro = true
            return
        }

        var owned: [String] = []
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            owned.append(transaction.productID)
        }

        let resolved = Self.resolveEntitlements(from: owned)
        isLegacyLifetimeOwner = resolved.legacy
        hasActiveSubscription = resolved.subscribed
        isPro = resolved.isPro

        #if DEBUG
            // Screenshot runs only. One store panel is required to show Pro VALUE unlocked and
            // working (owner law: no lock imagery in any panel), and the honest way to photograph
            // that is to photograph the app actually in that state — not to retouch a badge out.
            // Release compiles `DemoMode` to a constant false, so this cannot reach a shipped
            // binary; the entitlement resolution above is untouched and still the only rule.
            if DemoMode.showsProUnlocked {
                isPro = true
                hasActiveSubscription = true
            }
        #endif
    }

    /// The grandfathering decision, extracted as a pure function.
    ///
    /// `Transaction.currentEntitlements` cannot be faked in a unit test (and `SKTestSession`
    /// hangs rather than fails on StoreKit 26.x), so the RULE lives here where a test can pin
    /// it: 60 people paid once for this app and their access must survive every future change
    /// to the product ids, the plans, or this file. If that guarantee ever breaks it should
    /// break a test, not a customer.
    nonisolated static func resolveEntitlements(
        from productIDs: [String]
    ) -> (legacy: Bool, subscribed: Bool, isPro: Bool) {
        let legacy = productIDs.contains(legacyLifetimeProductID)
        let subscribed = productIDs.contains { Plan(rawValue: $0) != nil }
        return (legacy, subscribed, legacy || subscribed)
    }

    func listenForTransactions() async {
        for await result in Transaction.updates {
            guard let transaction = try? checkVerified(result) else { continue }
            await transaction.finish()
            // Any transaction change — purchase, renewal, revoke, refund, family-sharing grant —
            // re-derives the whole picture. Flipping a single flag here is how a revoked
            // subscription keeps its access until the next cold start.
            await checkEntitlements()
        }
    }

    // MARK: - Error Mapping

    private func mapError(_ error: Error) -> String {
        if let storeKitError = error as? StoreKitError {
            switch storeKitError {
            case .networkError:
                return L10n.purchaseErrorNetwork
            case .notAvailableInStorefront, .notEntitled:
                return L10n.purchaseErrorNotAllowed
            default:
                return L10n.purchaseErrorGeneric
            }
        }
        if let purchaseError = error as? Product.PurchaseError {
            switch purchaseError {
            case .purchaseNotAllowed:
                return L10n.purchaseErrorNotAllowed
            default:
                return L10n.purchaseErrorGeneric
            }
        }
        return L10n.purchaseErrorGeneric
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case let .unverified(_, error):
            throw error
        case let .verified(item):
            return item
        }
    }
}
