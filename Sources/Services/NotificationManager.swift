import Foundation
import os
import UserNotifications

final class NotificationManager: Sendable {
    // MARK: - Identifiers

    private enum ID {
        static let dailyReminder = "daily_reminder"
        static let weeklySummary = "weekly_summary"
        static let lapsedUser = "lapsed_user"
        static let streakMilestone = "streak_milestone"
        static let streakBreak = "streak_break"
        static let approachingBest = "approaching_best"
        static let journeyDay1 = "journey_day1"
        static let journeyDay2 = "journey_day2"
        static let journeyDay3 = "journey_day3"
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                let hour = UserDefaults.standard.integer(forKey: "notificationHour")
                let minute = UserDefaults.standard.integer(forKey: "notificationMinute")
                let resolvedHour = hour == 0 && minute == 0 ? 21 : hour
                await scheduleDailyReminder(hour: resolvedHour, minute: minute)
            }
        } catch {
            AppLogger.notification.error("Notification authorization failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Daily Reminder (Rotating Messages)

    private var dailyReminderMessages: [String] {
        // Single source: these lines also appear on screens, and two copies is how one of
        // them keeps an emoji after a voice pass.
        [
            L10n.notifDailyReminder1,
            L10n.notifDailyReminder2,
            L10n.notifDailyReminder3,
            L10n.notifDailyReminder4,
            L10n.notifDailyReminder5,
            L10n.notifDailyReminder6,
            L10n.notifDailyReminder7,
        ]
    }

    func scheduleDailyReminder(hour: Int = 21, minute: Int = 0) async {
        guard UserDefaults.standard.bool(forKey: "dailyReminderEnabled") else {
            cancelNotifications(withPrefix: ID.dailyReminder)
            return
        }

        let center = UNUserNotificationCenter.current()
        cancelNotifications(withPrefix: ID.dailyReminder)

        for dayOffset in 0 ..< 7 {
            let content = UNMutableNotificationContent()
            content.title = "NoBuy"
            content.body = dailyReminderMessages[dayOffset % dailyReminderMessages.count]
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.weekday = dayOffset + 1

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(ID.dailyReminder)_\(dayOffset)",
                content: content,
                trigger: trigger
            )

            do { try await center.add(request) } catch { AppLogger.notification.error("Failed to schedule notification: \(error.localizedDescription)") }
        }
    }

    func cancelDailyReminder() {
        cancelNotifications(withPrefix: ID.dailyReminder)
    }

    // MARK: - Streak Notification

    func scheduleStreakNotification(streak: Int) async {
        guard UserDefaults.standard.bool(forKey: "streakNotificationsEnabled") else { return }
        guard streak > 0 else { return }

        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "\(streak) " + L10n.notifStreakDaySuffix
        content.sound = .default

        switch streak {
        case 1:
            content.body = L10n.notifStreak1
        case 3:
            content.body = L10n.notifStreak3
        case 7:
            content.body = L10n.notifStreak7
        case 14:
            content.body = L10n.notifStreak14
        case 30:
            content.body = L10n.notifStreak30
        case 60:
            content.body = L10n.notifStreak60
        case 90:
            content.body = L10n.notifStreak90
        case 100:
            content.body = L10n.notifStreak100
        case 180:
            content.body = L10n.notifStreak180
        case 365:
            content.body = L10n.notifStreak365
        default:
            if streak % 5 == 0 {
                content.body = "Day \(streak) without an unnecessary purchase."
            } else {
                return
            }
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(ID.streakMilestone)_\(streak)",
            content: content,
            trigger: trigger
        )

        do { try await center.add(request) } catch { AppLogger.notification.error("Failed to schedule notification: \(error.localizedDescription)") }
    }

    // MARK: - Streak Break (Compassionate)

    func scheduleStreakBreakNotification(previousStreak: Int) async {
        guard UserDefaults.standard.bool(forKey: "streakNotificationsEnabled") else { return }
        guard previousStreak > 0 else { return }

        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Streak ended"
        content.sound = .default

        let messages = [
            L10n.notifStreakBreak1,
            "You held it for \(previousStreak) days. That still counts.",
            L10n.notifStreakBreak3,
        ]

        content.body = messages.randomElement()!

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(
            identifier: ID.streakBreak,
            content: content,
            trigger: trigger
        )

        do { try await center.add(request) } catch { AppLogger.notification.error("Failed to schedule notification: \(error.localizedDescription)") }
    }

    // MARK: - Approaching Personal Best

    func scheduleApproachingBestNotification(currentStreak: Int, longestStreak: Int) async {
        guard UserDefaults.standard.bool(forKey: "streakNotificationsEnabled") else { return }
        guard longestStreak > 1, currentStreak == longestStreak - 1 else { return }

        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = L10n.notifApproachingBestTitle
        content.body = "Your best run is \(longestStreak) days. Tomorrow matches it."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: ID.approachingBest,
            content: content,
            trigger: trigger
        )

        do { try await center.add(request) } catch { AppLogger.notification.error("Failed to schedule notification: \(error.localizedDescription)") }
    }

    // MARK: - Weekly Summary (Sunday 19:00)

    func scheduleWeeklySummary() async {
        guard UserDefaults.standard.bool(forKey: "weeklySummaryEnabled") else {
            cancelNotifications(withPrefix: ID.weeklySummary)
            return
        }

        let center = UNUserNotificationCenter.current()
        cancelNotifications(withPrefix: ID.weeklySummary)

        let content = UNMutableNotificationContent()
        content.title = L10n.notifWeeklySummaryTitle
        content.body = L10n.notifWeeklySummaryBody
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 1
        dateComponents.hour = 19
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: ID.weeklySummary,
            content: content,
            trigger: trigger
        )

        do { try await center.add(request) } catch { AppLogger.notification.error("Failed to schedule notification: \(error.localizedDescription)") }
    }

    func cancelWeeklySummary() {
        cancelNotifications(withPrefix: ID.weeklySummary)
    }

    // MARK: - Lapsed User Re-engagement — REMOVED in v2.0.0
    //
    // A "you have not logged in two days" nudge is the one class the onboarding card explicitly
    // disclaims ("no marketing"), and it was the only one no preference could switch off. It is
    // gone rather than gated: the product's own free-tier promise is that it never nags.
    //
    // The cancel survives so a v1.2 install that already has one queued has it withdrawn.
    func cancelLapsedUserNotification() {
        cancelNotifications(withPrefix: ID.lapsedUser)
    }

    func scheduleOnboardingJourney() async {
        let center = UNUserNotificationCenter.current()

        let journeyMessages: [(id: String, delay: TimeInterval, body: String)] = [
            (
                ID.journeyDay1,
                24 * 3600,
                "Log your first day whenever you are ready. The streak starts there."
            ),
            (
                ID.journeyDay2,
                48 * 3600,
                "When something is pulling at you, the Impulse Checklist is one tap from Today."
            ),
            (
                ID.journeyDay3,
                72 * 3600,
                "Three days in. Stats shows what the pattern looks like so far."
            ),
        ]

        for message in journeyMessages {
            let content = UNMutableNotificationContent()
            content.title = "NoBuy"
            content.body = message.body
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: message.delay,
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: message.id,
                content: content,
                trigger: trigger
            )

            do { try await center.add(request) } catch { AppLogger.notification.error("Failed to schedule notification: \(error.localizedDescription)") }
        }
    }

    // MARK: - Remove All

    func removeAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Helpers

    /// async/await rather than the completion-handler form: a closure handed to
    /// `getPendingNotificationRequests` runs on the framework's own queue, and capturing
    /// non-Sendable state across that boundary is the crash class the simulator never shows
    /// (`IOS/CLAUDE.md` — the surface the simulator cannot reach).
    private func cancelNotifications(withPrefix prefix: String) {
        Task {
            let center = UNUserNotificationCenter.current()
            let requests = await center.pendingNotificationRequests()
            let ids = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(prefix) }
            guard !ids.isEmpty else { return }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
