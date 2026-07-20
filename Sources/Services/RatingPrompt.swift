import Foundation
import Observation
import StoreKit
import SwiftUI
import UIKit

/// Asks for an App Store review only at a genuinely earned moment — a no-spend
/// day that lands on a streak milestone — and always through an honest two-step
/// card: "Love it" opens Apple's native prompt, "Could be better" routes to
/// private feedback in Mail instead of a public one-star. Never a fake-star UI
/// that filters reviews (Apple HIG + TheKnack honest-brand rule).
///
/// A caller invokes ``noteMilestone(currentStreak:)`` right after the positive
/// moment; this manager quietly decides whether the timing is right and arms
/// ``pendingPrePrompt``. The presenting screen chooses when to actually show
/// the card (after celebrations have finished), so the ask never interrupts.
///
/// The 60-day cooldown is recorded the moment the card is armed, so dismissing
/// the card without choosing still counts as the ask. Keeps the 1.1.x
/// `lastRatingPromptDate` key so already-prompted users aren't re-asked early.
/// Apple independently caps the native prompt at three per 365 days.
@Observable @MainActor
final class RatingPrompt {
    static let shared = RatingPrompt()

    /// Streak lengths the app already celebrates as milestones.
    private nonisolated static let milestones: Set<Int> = [7, 14, 30, 60, 100]
    /// Courtesy floor between asks; Apple's own 3/year cap sits above this.
    private nonisolated static let cooldown: TimeInterval = 60 * 24 * 60 * 60
    private nonisolated static let lastPromptKey = "lastRatingPromptDate"

    /// Private feedback channel for the "could be better" path — an unhappy tap
    /// vents to us in Mail instead of a public one-star.
    private nonisolated static let feedbackMailto =
        "mailto:theknack2020@gmail.com?subject=NoBuy%20Feedback"

    /// Drives the in-app pre-prompt card. Armed at a milestone; the presenting
    /// screen decides when to surface the card.
    var pendingPrePrompt = false

    /// The streak that armed the card, for the card's copy.
    private(set) var milestoneStreak = 0

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Record that a no-spend day just landed on `currentStreak`. Arms the
    /// pre-prompt card when the streak is a milestone and the cooldown allows.
    ///
    /// ⛔ Only ever call this after something the person will feel good about.
    /// Never after an error, a cancel, or any friction.
    func noteMilestone(currentStreak: Int) {
        let raw = defaults.double(forKey: Self.lastPromptKey)
        let lastPrompt = raw > 0 ? Date(timeIntervalSince1970: raw) : nil
        guard Self.shouldShowPrePrompt(currentStreak: currentStreak, lastPrompt: lastPrompt)
        else { return }

        // Record the ask now so the cooldown applies to the pre-prompt itself:
        // dismissing the card without choosing still counts as having asked.
        defaults.set(Date.now.timeIntervalSince1970, forKey: Self.lastPromptKey)
        milestoneStreak = currentStreak
        pendingPrePrompt = true
    }

    /// "Love it" — the only path to Apple's native rating prompt (itself capped
    /// at 3/365 by iOS). The card passes its `@Environment(\.requestReview)`.
    func lovedIt(requestReview: RequestReviewAction) {
        pendingPrePrompt = false
        requestReview()
    }

    /// "Could be better" — route to private feedback so the gripe reaches us,
    /// not a public one-star.
    func notForMe() {
        pendingPrePrompt = false
        guard let url = URL(string: Self.feedbackMailto) else { return }
        UIApplication.shared.open(url) { opened in
            if !opened {
                AppLogger.general.info("Feedback mail could not open (no mail account configured).")
            }
        }
    }

    /// Card dismissed without choosing; the cooldown was already recorded.
    func dismissed() {
        pendingPrePrompt = false
    }

    /// The pure timing gate — milestone streak + 60-day cooldown. Extracted as
    /// a static, side-effect-free function so the cadence contract is pinned in
    /// tests independently of UserDefaults and SwiftUI.
    nonisolated static func shouldShowPrePrompt(
        currentStreak: Int,
        lastPrompt: Date?,
        now: Date = .now
    ) -> Bool {
        guard milestones.contains(currentStreak) else { return false }
        guard let last = lastPrompt else { return true }
        return now.timeIntervalSince(last) >= cooldown
    }

    #if DEBUG
        /// Clears review cadence state (development / UI-test resets only).
        func resetForTesting() {
            defaults.removeObject(forKey: Self.lastPromptKey)
            pendingPrePrompt = false
            milestoneStreak = 0
        }
    #endif
}
