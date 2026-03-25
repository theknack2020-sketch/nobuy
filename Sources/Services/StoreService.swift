import Foundation
import StoreKit
import Observation
import os

@Observable
@MainActor
final class StoreService {
    static let shared = StoreService()

    private(set) var isPro = false
    private(set) var product: Product?
    private(set) var purchaseState: PurchaseState = .idle
    private(set) var restoreState: RestoreState = .idle

    private let productID = "com.ufukozdemir.nobuy.pro"
    // NOTE: If family sharing is enabled, update the entitlement in the
    // StoreKit configuration file to set isFamilyShareable = true on the product.
    // Currently this is a non-consumable without family sharing.
    static let freeCategoryLimit = 3

    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case purchased
        case failed(String)
    }

    enum RestoreState: Equatable {
        case idle
        case success
        case failed
    }

    // MARK: - Analytics Tracking

    @ObservationIgnored
    private let paywallShownCountKey = "paywallShownCount"
    @ObservationIgnored
    private let paywallLastShownDateKey = "paywallLastShownDate"
    @ObservationIgnored
    private let paywallLastDismissDateKey = "paywallLastDismissDate"

    var purchaseCount: Int {
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
    func trackPaywallShown() {
        purchaseCount += 1
        paywallLastShownDate = .now
    }

    /// Track that the paywall was dismissed without purchase
    func trackPaywallDismissed() {
        paywallLastDismissDate = .now
    }

    /// Don't show paywall within 24h of last dismiss, unless the user hit a milestone
    func canShowPaywall(atMilestone: Bool = false) -> Bool {
        if isPro { return false }
        if atMilestone { return true }
        guard let lastDismiss = paywallLastDismissDate else { return true }
        return Date.now.timeIntervalSince(lastDismiss) > 86400 // 24 hours
    }

    // MARK: - Formatted Price

    var formattedPrice: String? {
        product?.displayPrice
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

    /// Soft paywall banner shown count (read-only convenience)
    var softPaywallShownCount: Int {
        UserDefaults.standard.integer(forKey: "softPaywallShownCount")
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [productID])
            product = products.first
            if product == nil {
                AppLogger.store.warning("No products returned for \(productID)")
            }
        } catch {
            AppLogger.store.error("Failed to load products: \(error.localizedDescription)")
            // Product stays nil — PaywallView will show fallback UI
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product else {
            purchaseState = .failed("Unable to load product. Please check your connection and try again.")
            return
        }
        purchaseState = .purchasing

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                isPro = true
                purchaseState = .purchased
                await transaction.finish()
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
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

    func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == productID {
                isPro = true
                return
            }
        }
    }

    func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result),
               transaction.productID == productID {
                isPro = true
                await transaction.finish()
            }
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
        case .unverified(_, let error):
            throw error
        case .verified(let item):
            return item
        }
    }
}
