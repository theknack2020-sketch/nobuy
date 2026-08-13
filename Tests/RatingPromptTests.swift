import Foundation
import ReviewGate
import Testing
@testable import NoBuy

/// v2.0.0 moved the cadence into TheKnackKit's `ReviewGate`, so these tests pin two things:
/// the shared policy the app declares, and the migration that stops an already-asked 1.1.x
/// user from being asked again the same week.
@Suite("RatingPrompt gate")
struct RatingPromptTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private let policy = ReviewPromptPolicy(
        minPositiveActions: 3,
        minSessions: 2,
        cooldownDays: 90,
        maxPromptsPerYear: 3
    )

    // MARK: - Policy

    @Test("Enough positive actions and sessions, never asked before, offers the card")
    func offersOnceEarned() {
        let state = ReviewPromptState(positiveActions: 3, sessions: 2, lastPromptedAt: nil)
        #expect(shouldOfferPrePrompt(state: state, policy: policy, now: now))
    }

    @Test("Too few positive actions never asks")
    func tooFewActions() {
        let state = ReviewPromptState(positiveActions: 2, sessions: 5, lastPromptedAt: nil)
        #expect(!shouldOfferPrePrompt(state: state, policy: policy, now: now))
    }

    @Test("Too few sessions never asks")
    func tooFewSessions() {
        let state = ReviewPromptState(positiveActions: 9, sessions: 1, lastPromptedAt: nil)
        #expect(!shouldOfferPrePrompt(state: state, policy: policy, now: now))
    }

    @Test("A recent ask suppresses the card inside the 90-day cooldown")
    func recentAskSuppresses() {
        let thirtyDaysAgo = now.addingTimeInterval(-30 * 24 * 60 * 60)
        let state = ReviewPromptState(
            positiveActions: 10, sessions: 10,
            lastPromptedAt: thirtyDaysAgo, promptsThisYear: 1, yearAnchor: thirtyDaysAgo
        )
        #expect(!shouldOfferPrePrompt(state: state, policy: policy, now: now))
    }

    @Test("An expired cooldown allows the next ask")
    func expiredCooldownAsksAgain() {
        let hundredDaysAgo = now.addingTimeInterval(-100 * 24 * 60 * 60)
        let state = ReviewPromptState(
            positiveActions: 10, sessions: 10,
            lastPromptedAt: hundredDaysAgo, promptsThisYear: 1, yearAnchor: hundredDaysAgo
        )
        #expect(shouldOfferPrePrompt(state: state, policy: policy, now: now))
    }

    @Test("Apple's three-per-year ceiling is respected even when everything else qualifies")
    func yearlyCapHolds() {
        let hundredDaysAgo = now.addingTimeInterval(-100 * 24 * 60 * 60)
        let state = ReviewPromptState(
            positiveActions: 50, sessions: 50,
            lastPromptedAt: hundredDaysAgo, promptsThisYear: 3, yearAnchor: hundredDaysAgo
        )
        #expect(!shouldOfferPrePrompt(state: state, policy: policy, now: now))
    }

    // MARK: - Migration from 1.1.x

    @Test("A fresh install starts from an empty state")
    func freshInstallState() {
        let defaults = Self.emptyDefaults()
        let state = RatingPrompt.loadState(from: defaults)
        #expect(state.positiveActions == 0)
        #expect(state.sessions == 0)
        #expect(state.lastPromptedAt == nil)
    }

    @Test("A 1.1.x user who was already asked carries that date forward")
    func migratesLegacyPromptDate() {
        let defaults = Self.emptyDefaults()
        let askedAt = now.addingTimeInterval(-10 * 24 * 60 * 60)
        defaults.set(askedAt.timeIntervalSince1970, forKey: "lastRatingPromptDate")

        let state = RatingPrompt.loadState(from: defaults)
        #expect(state.lastPromptedAt != nil)
        #expect(state.promptsThisYear == 1)
        // The whole point of the migration: still inside the cooldown, so no immediate re-ask
        // even once the action and session counts are met.
        let earned = ReviewPromptState(
            positiveActions: 5, sessions: 5,
            lastPromptedAt: state.lastPromptedAt,
            promptsThisYear: state.promptsThisYear,
            yearAnchor: state.yearAnchor
        )
        #expect(!shouldOfferPrePrompt(state: earned, policy: policy, now: now))
    }

    @Test("Stored state wins over the legacy key once it exists")
    func storedStateWins() {
        let defaults = Self.emptyDefaults()
        defaults.set(now.timeIntervalSince1970, forKey: "lastRatingPromptDate")
        let stored = ReviewPromptState(positiveActions: 7, sessions: 4, lastPromptedAt: nil)
        defaults.set(try? JSONEncoder().encode(stored), forKey: "reviewGateState")

        let state = RatingPrompt.loadState(from: defaults)
        #expect(state.positiveActions == 7)
        #expect(state.sessions == 4)
        #expect(state.lastPromptedAt == nil)
    }

    private static func emptyDefaults() -> UserDefaults {
        let suite = "RatingPromptTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
