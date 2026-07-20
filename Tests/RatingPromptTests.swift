import Foundation
import Testing
@testable import NoBuy

@Suite("RatingPrompt gate")
struct RatingPromptTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("Milestone streak with no prior ask shows the card")
    func milestoneWithNoPriorAsk() {
        #expect(RatingPrompt.shouldShowPrePrompt(currentStreak: 7, lastPrompt: nil, now: now))
        #expect(RatingPrompt.shouldShowPrePrompt(currentStreak: 30, lastPrompt: nil, now: now))
        #expect(RatingPrompt.shouldShowPrePrompt(currentStreak: 100, lastPrompt: nil, now: now))
    }

    @Test("Recent ask suppresses the card within the 60-day cooldown")
    func recentAskSuppresses() {
        let thirtyDaysAgo = now.addingTimeInterval(-30 * 24 * 60 * 60)
        #expect(!RatingPrompt.shouldShowPrePrompt(currentStreak: 7, lastPrompt: thirtyDaysAgo, now: now))
    }

    @Test("Non-milestone streaks never ask")
    func nonMilestoneNeverAsks() {
        #expect(!RatingPrompt.shouldShowPrePrompt(currentStreak: 0, lastPrompt: nil, now: now))
        #expect(!RatingPrompt.shouldShowPrePrompt(currentStreak: 8, lastPrompt: nil, now: now))
        #expect(!RatingPrompt.shouldShowPrePrompt(currentStreak: 99, lastPrompt: nil, now: now))
    }

    @Test("Expired cooldown allows the next milestone ask")
    func expiredCooldownAsksAgain() {
        let seventyDaysAgo = now.addingTimeInterval(-70 * 24 * 60 * 60)
        #expect(RatingPrompt.shouldShowPrePrompt(currentStreak: 14, lastPrompt: seventyDaysAgo, now: now))
    }
}
