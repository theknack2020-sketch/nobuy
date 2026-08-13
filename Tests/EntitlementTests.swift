import Foundation
import Testing
@testable import NoBuy

/// The v2.0.0 monetisation migration's one non-negotiable: **the 60 people who bought the
/// retired one-time unlock keep everything, permanently.**
///
/// `Transaction.currentEntitlements` cannot be driven from a unit test, and `SKTestSession`
/// hangs rather than fails on StoreKit 26.x (memory `sktest-26x-purchase-hangs-not-fails`), so
/// the decision was extracted into a pure function and pinned here. A refactor that drops the
/// legacy id, renames a plan, or "simplifies" the entitlement walk fails these tests instead of
/// silently downgrading paying customers.
@Suite("Entitlement resolution (grandfathering)")
struct EntitlementTests {
    private let legacy = StoreService.legacyLifetimeProductID
    private let monthly = StoreService.Plan.monthly.rawValue
    private let yearly = StoreService.Plan.yearly.rawValue

    @Test("Nothing owned means no Pro")
    func emptyIsFree() {
        let r = StoreService.resolveEntitlements(from: [])
        #expect(!r.isPro)
        #expect(!r.legacy)
        #expect(!r.subscribed)
    }

    @Test("The retired one-time unlock still grants Pro, forever")
    func legacyUnlockGrantsPro() {
        let r = StoreService.resolveEntitlements(from: [legacy])
        #expect(r.isPro, "a paying customer from before the migration lost access")
        #expect(r.legacy)
        #expect(!r.subscribed)
    }

    @Test("Either subscription grants Pro")
    func subscriptionsGrantPro() {
        for id in [monthly, yearly] {
            let r = StoreService.resolveEntitlements(from: [id])
            #expect(r.isPro)
            #expect(r.subscribed)
            #expect(!r.legacy)
        }
    }

    /// The two grants are not mutually exclusive: an early supporter can also subscribe (to
    /// support the app, or by accident). Settings must still show them as an early supporter,
    /// so both flags have to survive.
    @Test("A legacy owner who also subscribes keeps BOTH standings")
    func legacyPlusSubscription() {
        let r = StoreService.resolveEntitlements(from: [legacy, yearly])
        #expect(r.isPro)
        #expect(r.legacy)
        #expect(r.subscribed)
    }

    @Test("An unrelated product id grants nothing")
    func unknownProductIsIgnored() {
        let r = StoreService.resolveEntitlements(from: ["com.ufukozdemir.nobuy.something.else"])
        #expect(!r.isPro)
    }

    /// The legacy id is a LIVE App Store product with 60 owners; it can never be renamed.
    @Test("The legacy product id is exactly the one that shipped")
    func legacyIdIsFrozen() {
        #expect(StoreService.legacyLifetimeProductID == "com.ufukozdemir.nobuy.pro")
    }

    @Test("Plan ids match the products created in App Store Connect")
    func planIdsMatchASC() {
        #expect(StoreService.Plan.monthly.rawValue == "com.ufukozdemir.nobuy.monthly")
        #expect(StoreService.Plan.yearly.rawValue == "com.ufukozdemir.nobuy.yearly")
    }
}

/// The free tier's caps, pinned to the numbers the paywall states out loud. If a cap moves, the
/// sentence the user reads moves with it — these tests are what stop the two drifting apart.
@Suite("Free-tier caps")
struct FreeTierTests {
    @MainActor
    private func freeStore() -> StoreService {
        // The shared instance starts un-entitled in tests; DemoMode is off here.
        StoreService.shared
    }

    @Test("The record window is 90 days and the waiting list holds 3")
    func capsAreTheDeclaredNumbers() {
        #expect(StoreService.freeRecordWindowDays == 90)
        #expect(StoreService.freeWaitingSlots == 3)
        #expect(StoreService.freeCategoryLimit == 3)
    }

    @Test("A day inside the window opens; a day before it does not")
    @MainActor
    func windowBoundary() {
        let store = freeStore()
        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_800_000_000)

        guard let inside = calendar.date(byAdding: .day, value: -89, to: now),
              let outside = calendar.date(byAdding: .day, value: -90, to: now)
        else { return }

        // Only meaningful while un-entitled — Pro opens everything.
        if !store.isPro {
            #expect(store.canOpenRecord(on: inside, now: now, calendar: calendar))
            #expect(!store.canOpenRecord(on: outside, now: now, calendar: calendar))
        }
    }

    @Test("The waiting list stops at the third held item")
    @MainActor
    func waitingSlots() {
        let store = freeStore()
        if !store.isPro {
            #expect(store.canHoldAnotherItem(currentCount: 2))
            #expect(!store.canHoldAnotherItem(currentCount: 3))
        }
    }
}
