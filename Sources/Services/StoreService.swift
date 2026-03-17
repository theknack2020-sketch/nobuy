import Foundation
import StoreKit
import Observation

@Observable
@MainActor
final class StoreService {
    static let shared = StoreService()

    private(set) var isPro = false
    private(set) var product: Product?
    private(set) var purchaseState: PurchaseState = .idle

    private let productID = "com.ufukozdemir.nobuy.pro"
    static let freeCategoryLimit = 3

    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case purchased
        case failed(String)
    }

    private init() {}

    // MARK: - Gates

    func canAddCategory(currentCount: Int) -> Bool {
        isPro || currentCount < Self.freeCategoryLimit
    }

    func remainingFreeSlots(currentCount: Int) -> Int {
        isPro ? .max : max(Self.freeCategoryLimit - currentCount, 0)
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [productID])
            product = products.first
        } catch {
            print("[StoreService] Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product else { return }
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
            purchaseState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Restore

    func restore() async {
        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            print("[StoreService] Restore failed: \(error)")
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
