import Foundation
import UserNotifications
import os

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
        [
            "Don't forget to log today! 💪",
            "Did you spend today? Update your log 📝",
            "Check your streak — every day counts 🔥",
            "How was your mindful spending day? Log it ✅",
            "Another day done. Was it a NoBuy day? 🤔",
            "Small steps, big changes. Log today 🌱",
            "Don't forget your spending log! We're waiting 💚",
        ]
    }

    func scheduleDailyReminder(hour: Int = 21, minute: Int = 0) async {
        guard UserDefaults.standard.bool(forKey: "dailyReminderEnabled") else {
            cancelNotifications(withPrefix: ID.dailyReminder)
            return
        }

        let center = UNUserNotificationCenter.current()
        cancelNotifications(withPrefix: ID.dailyReminder)

        for dayOffset in 0..<7 {
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

            try? await center.add(request)
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
        content.title = "🔥 \(streak) " + "Days!"
        content.sound = .default

        switch streak {
        case 1:
            content.body = "Your first no-spend day — great start!"
        case 3:
            content.body = "3 days in a row! A habit is forming."
        case 7:
            content.body = "One week no-spend! You're on fire 🎯"
        case 14:
            content.body = "2-week streak! It's a lifestyle now 💪"
        case 30:
            content.body = "30 days! Legend. You're a savings machine 🏆"
        case 60:
            content.body = "60 days! Two months strong. Incredible 🌟"
        case 90:
            content.body = "90 days! A quarter year no-spend. Legendary 🏅"
        case 100:
            content.body = "💯 100 days! A true milestone!"
        case 180:
            content.body = "Half a year streak! 180 days of discipline 🎖️"
        case 365:
            content.body = "🎉 ONE YEAR! 365 days no-spend. Unbelievable!"
        default:
            if streak % 5 == 0 {
                content.body = "Day \(streak) no-spend, keep it up!"
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

        try? await center.add(request)
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
            "One day doesn't change everything. Tomorrow is a fresh start.",
            "You were strong for \(previousStreak) days. That's still an achievement.",
            "Falling isn't failing. Tomorrow's with you 💚",
        ]

        content.body = messages.randomElement()!

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(
            identifier: ID.streakBreak,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    // MARK: - Approaching Personal Best

    func scheduleApproachingBestNotification(currentStreak: Int, longestStreak: Int) async {
        guard UserDefaults.standard.bool(forKey: "streakNotificationsEnabled") else { return }
        guard longestStreak > 1, currentStreak == longestStreak - 1 else { return }

        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "1 day from your record! 🏆"
        content.body = "Your longest streak was \(longestStreak) days. You can break it tomorrow!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: ID.approachingBest,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
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
        content.title = "Weekly Summary 📊"
        content.body = "Open NoBuy to see this week's performance."
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

        try? await center.add(request)
    }

    func cancelWeeklySummary() {
        cancelNotifications(withPrefix: ID.weeklySummary)
    }

    // MARK: - Lapsed User Re-engagement

    func scheduleLapsedUserNotification() async {
        let center = UNUserNotificationCenter.current()
        cancelNotifications(withPrefix: ID.lapsedUser)

        let content = UNMutableNotificationContent()
        content.title = "NoBuy"
        content.sound = .default

        let messages = [
            "We miss you! How about logging today? 💚",
            "No records for 2 days. Protect your streak! 🔥",
            "Great day to come back. We're waiting 🌱",
        ]
        content.body = messages.randomElement()!

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 2 * 24 * 60 * 60,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: ID.lapsedUser,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    // MARK: - Onboarding Journey (Day 1-3)

    func scheduleOnboardingJourney() async {
        let center = UNUserNotificationCenter.current()

        let journeyMessages: [(id: String, delay: TimeInterval, body: String)] = [
            (
                ID.journeyDay1,
                24 * 3600,
                "Welcome to NoBuy! 👋 Log your first day and see your streak grow."
            ),
            (
                ID.journeyDay2,
                48 * 3600,
                "Tip: Use the Impulse Checklist when you feel the urge to buy. It works! 🧠"
            ),
            (
                ID.journeyDay3,
                72 * 3600,
                "Day 3! Check your Stats tab to see your progress. You're building a habit! 📊"
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

            try? await center.add(request)
        }
    }

    // MARK: - Remove All

    func removeAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Helpers

    private func cancelNotifications(withPrefix prefix: String) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(prefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
