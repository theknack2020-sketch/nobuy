import Foundation
import Observation

@Observable
@MainActor
final class SoftPaywallTracker {
    static let shared = SoftPaywallTracker()

    private let actionCountKey = "softPaywallActionCount"
    private let hasShownKey = "softPaywallHasShown"
    private let triggerThreshold = 3

    var shouldShowPaywall = false

    var actionCount: Int {
        UserDefaults.standard.integer(forKey: actionCountKey)
    }

    private var hasShown: Bool {
        UserDefaults.standard.bool(forKey: hasShownKey)
    }

    func trackAction() {
        let count = actionCount + 1
        UserDefaults.standard.set(count, forKey: actionCountKey)

        if count >= triggerThreshold && !hasShown {
            shouldShowPaywall = true
            UserDefaults.standard.set(true, forKey: hasShownKey)
        }
    }

    func resetShown() {
        shouldShowPaywall = false
    }
}
