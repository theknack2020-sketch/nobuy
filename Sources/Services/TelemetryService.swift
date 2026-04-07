import os
import SwiftUI
import TelemetryDeck

private let logger = Logger(subsystem: "com.ufukozdemir.nobuy", category: "Telemetry")

/// Centralized analytics — privacy-first, no personal data.
@MainActor
enum TelemetryService {
    private nonisolated(unsafe) static var isConfigured = false

    private static let appID: String = {
        if let envID = ProcessInfo.processInfo.environment["NOBUY_TELEMETRY_APP_ID"], !envID.isEmpty {
            return envID
        }
        return "REPLACE_WITH_TELEMETRYDECK_APP_ID"
    }()

    static func initialize() {
        guard appID != "REPLACE_WITH_TELEMETRYDECK_APP_ID" else {
            logger.warning("TelemetryDeck App ID not configured — analytics disabled")
            return
        }
        let config = TelemetryDeck.Config(appID: appID)
        TelemetryDeck.initialize(config: config)
        isConfigured = true
        logger.info("TelemetryDeck initialized")
    }

    static func trackScreen(_ name: String) {
        guard isConfigured else { return }
        TelemetryDeck.signal("screen_viewed", parameters: ["screen": name])
    }

    static func trackEvent(_ name: String, properties: [String: String] = [:]) {
        guard isConfigured else { return }
        TelemetryDeck.signal(name, parameters: properties)
    }

    // MARK: - NoBuy Events

    static func trackDayMarked(type: String) {
        trackEvent("day_marked", properties: ["type": type])
    }

    static func trackStreakMilestone(_ days: Int) {
        trackEvent("streak_milestone", properties: ["days": "\(days)"])
    }

    static func trackStreakBroken(days: Int) {
        trackEvent("streak_broken", properties: ["days": "\(days)"])
    }

    static func trackStreakFreeze() {
        trackEvent("streak_freeze_used")
    }

    static func trackImpulseChecklist(result: String) {
        trackEvent("impulse_checklist", properties: ["result": result])
    }

    static func trackUrgeSurfing(completed: Bool, durationSeconds: Int) {
        trackEvent("urge_surfing", properties: [
            "completed": "\(completed)",
            "duration_seconds": "\(durationSeconds)",
        ])
    }

    static func trackWaitingListItem(action: String) {
        trackEvent("waiting_list", properties: ["action": action])
    }

    static func trackChallengeStarted(days: Int) {
        trackEvent("challenge_started", properties: ["days": "\(days)"])
    }

    static func trackChallengeCompleted(days: Int) {
        trackEvent("challenge_completed", properties: ["days": "\(days)"])
    }

    static func trackPurchaseCompleted() {
        trackEvent("pro_purchased")
    }

    static func trackPurchaseFailed(error: String) {
        trackEvent("purchase_failed", properties: ["error": error])
    }

    static func trackOnboardingCompleted() {
        trackEvent("onboarding_completed")
    }

    static func trackThemeChanged(_ theme: String) {
        trackEvent("theme_changed", properties: ["theme": theme])
    }

    static func trackAchievementUnlocked(_ id: String) {
        trackEvent("achievement_unlocked", properties: ["achievement": id])
    }

    static func trackShareCard() {
        trackEvent("share_card_generated")
    }
}
