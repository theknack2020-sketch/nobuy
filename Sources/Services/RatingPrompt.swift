import StoreKit
import UIKit

/// Fires the native App Store review prompt at a genuine "earned" moment —
/// right after the user logs a no-spend day that lands on a streak milestone.
///
/// Shares the `lastRatingPromptDate` throttle with `SettingsScreen` so the two
/// entry points never double-prompt inside the 60-day window. Apple additionally
/// caps `SKStoreReviewController` to a few prompts per year system-wide.
enum RatingPrompt {
    private static let lastPromptKey = "lastRatingPromptDate"
    private static let minInterval: TimeInterval = 60 * 24 * 60 * 60 // 60 days

    /// Streak lengths the app already celebrates as milestones.
    private static let milestones: Set<Int> = [7, 14, 30, 60, 100]

    /// Request a review if the just-completed no-spend streak hit a milestone
    /// and the 60-day throttle allows it. No-op otherwise.
    @MainActor
    static func requestAfterNoSpendDay(currentStreak: Int) {
        guard milestones.contains(currentStreak) else { return }

        let defaults = UserDefaults.standard
        let lastPrompt = Date(timeIntervalSince1970: defaults.double(forKey: lastPromptKey))
        guard Date.now.timeIntervalSince(lastPrompt) >= minInterval else { return }

        // Delay so the day-edit sheet has dismissed and the main scene is active,
        // matching the timing used by the Settings entry point.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            else { return }

            SKStoreReviewController.requestReview(in: scene)
            defaults.set(Date.now.timeIntervalSince1970, forKey: lastPromptKey)
        }
    }
}
