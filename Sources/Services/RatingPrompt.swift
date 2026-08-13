import Foundation
import Observation
import ReviewGate
import StoreKit
import SwiftUI
import UIKit

/// Asks for an App Store review only at a genuinely earned moment, and always through an honest
/// two-step card: "Love it" opens Apple's native prompt, "Could be better" routes to private
/// feedback in Mail instead of a public one-star. Never a fake-star UI that filters reviews
/// (Apple HIG + TheKnack honest-brand rule).
///
/// **v2.0.0 — the cadence now comes from TheKnackKit's `ReviewGateManager`, not from local logic.**
/// Two reasons, one legal and one measured:
///
/// · The review-prompt law names `ReviewGate` as the portfolio's canonical implementation, and a
///   local re-implementation is the prose-only binding rule 8 forbids — `product-completeness`
///   reports it as `reviewgate.missing` regardless of how well the copy behaves.
/// · The local copy only ever armed on a streak of exactly 7, 14, 30, 60 or 100 days. In a
///   no-spend tracker, seven consecutive qualifying days is a high bar, and the measured result
///   was 976 downloads and **zero ratings** between 2026-04 and 2026-08. The shared policy asks
///   after a few genuinely positive actions instead, while Apple's own 3-per-365-days cap and a
///   90-day cooldown keep it from ever becoming nagging.
///
/// A caller invokes ``noteMilestone(currentStreak:)`` right after a positive moment; this manager
/// decides whether the timing is right and arms ``pendingPrePrompt``. The presenting screen
/// chooses when to actually show the card (after celebrations have finished), so the ask never
/// interrupts.
@Observable @MainActor
final class RatingPrompt {
    static let shared = RatingPrompt()

    /// Persisted `ReviewPromptState`, as JSON.
    private nonisolated static let stateKey = "reviewGateState"
    /// The 1.1.x cooldown key. Still read at first launch so a user who was already asked under
    /// the old rules is not asked again immediately under the new ones.
    private nonisolated static let legacyLastPromptKey = "lastRatingPromptDate"

    /// Private feedback channel for the "could be better" path — an unhappy tap
    /// vents to us in Mail instead of a public one-star.
    private nonisolated static let feedbackMailto =
        "mailto:theknack2020@gmail.com?subject=NoBuy%20Feedback"

    /// Drives the in-app pre-prompt card. Armed at a positive moment; the presenting
    /// screen decides when to surface the card.
    var pendingPrePrompt = false

    /// The streak that armed the card, for the card's copy.
    private(set) var milestoneStreak = 0

    /// `UserDefaults` is documented as thread-safe but is not marked `Sendable`, and the gate's
    /// `persist` hook is a `@Sendable` closure. Stating that fact once, in this narrow box, is
    /// preferable to scattering `nonisolated(unsafe)` across call sites — the box exposes a
    /// single write and nothing else.
    private struct DefaultsBox: @unchecked Sendable {
        let defaults: UserDefaults
        func write(_ data: Data, forKey key: String) { defaults.set(data, forKey: key) }
    }

    private let defaults: UserDefaults
    private let gate: ReviewGateManager

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let box = DefaultsBox(defaults: defaults)
        gate = ReviewGateManager(
            state: Self.loadState(from: defaults),
            // Deliberately close to the house standard. `minSessions: 2` rather than 3 because
            // this app is used once a day by design: a third session means a third day, and the
            // positive-action count already carries the "has this person got value yet" question.
            policy: ReviewPromptPolicy(
                minPositiveActions: 3,
                minSessions: 2,
                cooldownDays: 90,
                maxPromptsPerYear: 3
            ),
            persist: { state in
                guard let data = try? JSONEncoder().encode(state) else { return }
                box.write(data, forKey: Self.stateKey)
            }
        )
    }

    /// Count an app open. Called once per cold start.
    func markSession() {
        guard !DemoMode.isActive else { return }
        gate.markSession()
    }

    /// Record that a no-spend day just landed on `currentStreak`.
    ///
    /// ⛔ Only ever call this after something the person will feel good about.
    /// Never after an error, a cancel, or any friction.
    func noteMilestone(currentStreak: Int) {
        guard !DemoMode.isActive else { return }
        gate.markPositiveAction()
        guard gate.shouldOffer() else { return }

        // Record the ask now so the cooldown applies to the pre-prompt itself:
        // dismissing the card without choosing still counts as having asked.
        gate.recordPrompted()
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

    // MARK: - Persistence + migration

    /// Reads the stored gate state, migrating a 1.1.x install on first run.
    ///
    /// The migration matters: without it, everyone who was already asked under the old rules
    /// would land on a fresh state and could be asked again the same week — the one outcome an
    /// honest prompt must never produce.
    nonisolated static func loadState(from defaults: UserDefaults) -> ReviewPromptState {
        if let data = defaults.data(forKey: stateKey),
           let decoded = try? JSONDecoder().decode(ReviewPromptState.self, from: data)
        {
            return decoded
        }

        let legacyRaw = defaults.double(forKey: legacyLastPromptKey)
        guard legacyRaw > 0 else { return ReviewPromptState() }

        let legacyDate = Date(timeIntervalSince1970: legacyRaw)
        return ReviewPromptState(
            positiveActions: 0,
            sessions: 0,
            lastPromptedAt: legacyDate,
            promptsThisYear: 1,
            yearAnchor: legacyDate
        )
    }

    #if DEBUG
        /// Clears review cadence state (development / UI-test resets only).
        func resetForTesting() {
            defaults.removeObject(forKey: Self.stateKey)
            defaults.removeObject(forKey: Self.legacyLastPromptKey)
            pendingPrePrompt = false
            milestoneStreak = 0
        }
    #endif
}
