import Foundation
import UserNotifications

final class NotificationManager: Sendable {

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                await scheduleDaily()
            }
        } catch {
            print("Notification authorization failed: \(error)")
        }
    }

    /// Schedule evening reminder: "Bugünü kaydetmeyi unutma!"
    func scheduleDaily() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        content.title = "NoBuy"
        content.body = "Bugünü kaydetmeyi unutma! 💪"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    /// Motivational notification based on streak
    func scheduleStreakNotification(streak: Int) async {
        guard streak > 0 else { return }

        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "🔥 \(streak) Gün!"
        content.sound = .default

        switch streak {
        case 1:
            content.body = "İlk harcamasız günün, güzel başlangıç!"
        case 3:
            content.body = "3 gün üst üste! Alışkanlık oluşuyor."
        case 7:
            content.body = "Bir hafta harcamasız! Harika gidiyorsun 🎯"
        case 14:
            content.body = "2 hafta streak! Artık bir yaşam tarzı 💪"
        case 30:
            content.body = "30 gün! Efsane. Sen bir tasarruf makinesisin 🏆"
        default:
            if streak % 5 == 0 {
                content.body = "\(streak). harcamasız günün, devam et!"
            } else {
                return // Don't spam for every day
            }
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_\(streak)",
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }
}
