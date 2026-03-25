import Foundation
import SwiftData
import Observation
import os

@MainActor
@Observable
final class HomeViewModel {
    var todayRecord: DayRecord?
    var streakInfo: StreakInfo = .empty
    var showSpendOptions = false
    var showStreakBreak = false
    var showFreezeOffer = false
    var previousStreakBeforeBreak = 0
    var lastError: String?
    var showDeleteConfirmation = false

    @ObservationIgnored
    private let userDefaults = UserDefaults.standard

    // MARK: - Streak Freeze State

    var streakFreezeCount: Int {
        get { userDefaults.integer(forKey: "streakFreezeCount") }
        set { userDefaults.set(newValue, forKey: "streakFreezeCount") }
    }

    var lastFreezeMonth: String {
        get { userDefaults.string(forKey: "lastFreezeMonth") ?? "" }
        set { userDefaults.set(newValue, forKey: "lastFreezeMonth") }
    }

    /// Pending context/records for applying freeze after user confirms
    @ObservationIgnored
    var pendingFreezeContext: ModelContext?
    @ObservationIgnored
    var pendingFreezeRecords: [DayRecord] = []
    @ObservationIgnored
    var pendingSpendAmount: Double?

    // MARK: - Challenge State

    var challengeDuration: Int {
        get { userDefaults.integer(forKey: "challengeDuration") }
        set { userDefaults.set(newValue, forKey: "challengeDuration") }
    }

    var challengeStartDate: Date? {
        get {
            let timestamp = userDefaults.double(forKey: "challengeStartDate")
            if timestamp > 0 {
                return Date(timeIntervalSince1970: timestamp)
            }
            return nil
        }
        set {
            if let date = newValue {
                userDefaults.set(date.timeIntervalSince1970, forKey: "challengeStartDate")
            } else {
                userDefaults.removeObject(forKey: "challengeStartDate")
            }
        }
    }

    var isChallengeActive: Bool {
        guard challengeDuration > 0, let start = challengeStartDate else { return false }
        let elapsed = Calendar.current.dateComponents([.day], from: start, to: .now).day ?? 0
        return elapsed < challengeDuration
    }

    var challengeDaysCompleted: Int {
        guard let start = challengeStartDate else { return 0 }
        let elapsed = Calendar.current.dateComponents([.day], from: start, to: .now).day ?? 0
        return min(elapsed, challengeDuration)
    }

    var challengeDaysRemaining: Int {
        max(challengeDuration - challengeDaysCompleted, 0)
    }

    var challengeProgress: Double {
        guard challengeDuration > 0 else { return 0 }
        return Double(challengeDaysCompleted) / Double(challengeDuration)
    }

    var isChallengeCompleted: Bool {
        guard challengeDuration > 0, challengeStartDate != nil else { return false }
        return challengeDaysCompleted >= challengeDuration
    }

    // MARK: - Savings Goal

    var savingsGoal: String {
        get { userDefaults.string(forKey: "savingsGoal") ?? "" }
    }

    var dailySpendingEstimate: Double {
        get { userDefaults.double(forKey: "dailySpendingEstimate") }
        set { userDefaults.set(newValue, forKey: "dailySpendingEstimate") }
    }

    var isTodayNoBuy: Bool {
        todayRecord?.isNoBuyDay ?? false
    }

    var isTodayRecorded: Bool {
        todayRecord != nil
    }

    var todayStatusText: String {
        guard let record = todayRecord else {
            return L10n.noRecordYet
        }
        if record.isFrozen {
            return "Freeze used today 🛡️"
        }
        if record.isNoBuyDay {
            return L10n.noBuyToday
        } else {
            return L10n.spentToday
        }
    }

    /// Estimated savings this month based on no-buy days × daily spending estimate
    var estimatedSavings: Double {
        Double(streakInfo.noBuyDaysThisMonth) * dailySpendingEstimate
    }

    /// Formatted estimated savings as currency
    var formattedEstimatedSavings: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: estimatedSavings)) ?? "$0"
    }

    /// Icon for the savings goal
    var savingsGoalIcon: String {
        switch savingsGoal {
        case "emergencyFund": return "shield.fill"
        case "vacation": return "airplane"
        case "debtFree": return "creditcard.trianglebadge.exclamationmark"
        case "discipline": return "brain.head.profile"
        default: return "target"
        }
    }

    /// Localized label for the savings goal
    var savingsGoalLabel: String {
        switch savingsGoal {
        case "emergencyFund": return L10n.goalEmergencyFund
        case "vacation": return L10n.goalVacation
        case "debtFree": return L10n.goalDebtFree
        case "discipline": return L10n.goalDiscipline
        case "": return ""
        default: return savingsGoal // Custom text from user
        }
    }

    /// Share text for streak sharing
    var shareText: String {
        let streak = streakInfo.currentStreak
        if streak == 0 {
            return "I'm starting my no-spend journey with NoBuy! 🌱"
        }
        let emoji: String
        switch streak {
        case 100...: emoji = "💯"
        case 60...: emoji = "👑"
        case 30...: emoji = "🏆"
        case 14...: emoji = "⭐"
        case 7...: emoji = "🔥"
        default: emoji = "🌱"
        }
        return "I've been on a \(streak)-day no-spend streak with NoBuy! \(emoji) #NoBuy #MindfulSpending"
    }

    /// Motivational text that varies based on streak length, day of week, and date-seeded randomization
    var todayMotivationalText: String {
        let streak = streakInfo.currentStreak
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: .now)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: .now) ?? 1

        if streak == 0 {
            let zeroMessages = [
                "Every achievement starts with the first step.",
                "Today could be a fresh start.",
                "Even one day makes a difference.",
            ]
            return zeroMessages[dayOfYear % zeroMessages.count]
        }

        if streak < 3 {
            let earlyMessages = [
                "You're doing great, keep going!",
                "Every day you're one step further.",
                "Starting is the hardest part — you've already done it.",
            ]
            return earlyMessages[dayOfYear % earlyMessages.count]
        }

        if streak < 7 {
            let midMessages = [
                "A habit is forming, don't stop!",
                "Keep this pace 🔥",
                "Discipline brought you here.",
            ]
            return midMessages[dayOfYear % midMessages.count]
        }

        if streak < 30 {
            if weekday == 1 || weekday == 7 {
                let weekendMessages = [
                    "Weekends test your goals. You're strong.",
                    "Weekends — best deals get missed, but you win 💪",
                ]
                return weekendMessages[dayOfYear % weekendMessages.count]
            }

            let weekMessages = [
                "\(streak) days! It's a habit now.",
                "Most people quit here. You keep going.",
                "Your savings grow every day 🌱",
            ]
            return weekMessages[dayOfYear % weekMessages.count]
        }

        let longMessages = [
            "Epic streak! A real lifestyle change.",
            "\(streak) days — you're an inspiration.",
            "This is a marathon, and you're winning 🏆",
        ]
        return longMessages[dayOfYear % longMessages.count]
    }

    // MARK: - Freeze Management

    /// Resets the monthly freeze counter if we're in a new month
    func resetMonthlyFreezeIfNeeded(isPro: Bool) {
        let currentMonth = Date.now.formatted(.dateTime.year().month())
        if lastFreezeMonth != currentMonth {
            lastFreezeMonth = currentMonth
            // Free users get 1 freeze per month; Pro gets unlimited (we reset to a high number)
            streakFreezeCount = isPro ? 99 : 1
        }
    }

    /// Whether the user has freezes available
    var hasFreezeAvailable: Bool {
        streakFreezeCount > 0
    }

    /// Display text for remaining freezes
    var freezeDisplayText: String {
        if streakFreezeCount >= 99 {
            return "🛡️ Unlimited freezes"
        }
        return "🛡️ \(streakFreezeCount) freezes left"
    }

    // MARK: - Actions

    func loadToday(records: [DayRecord]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        todayRecord = records.first { calendar.startOfDay(for: $0.date) == today }
        streakInfo = StreakCalculator.calculate(from: records)
    }

    func markNoBuy(context: ModelContext, allRecords: [DayRecord]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        if let existing = todayRecord {
            existing.didSpend = false
            existing.isMandatoryOnly = false
            existing.isFrozen = false
        } else {
            let record = DayRecord(date: today, didSpend: false)
            context.insert(record)
            todayRecord = record
        }

        do {
            try context.save()
        } catch {
            AppLogger.data.error("Failed to save NoBuy record: \(error.localizedDescription)")
            lastError = "Failed to save your no-spend day. Please try again."
            return
        }
        HapticManager.noBuySuccess()
        SoundManager.playIfEnabled(.success)
        SoftPaywallTracker.shared.trackAction()

        var updated = allRecords.filter { calendar.startOfDay(for: $0.date) != today }
        if let current = todayRecord { updated.append(current) }
        streakInfo = StreakCalculator.calculate(from: updated)

        let streak = streakInfo.currentStreak
        let longest = streakInfo.longestStreak

        // Check achievements after every no-buy mark
        let totalNoBuyDays = updated.filter(\.isNoBuyDay).count
        AchievementManager.shared.checkAchievements(
            currentStreak: streak,
            totalNoBuyDays: totalNoBuyDays,
            records: updated
        )

        SpotlightService.indexStreak(streak)

        Task {
            do {
                let manager = NotificationManager()
                await manager.scheduleStreakNotification(streak: streak)

                if longest > 1, streak == longest - 1 {
                    await manager.scheduleApproachingBestNotification(
                        currentStreak: streak,
                        longestStreak: longest
                    )
                }

                await manager.scheduleLapsedUserNotification()
            }
        }
    }

    func markSpent(context: ModelContext, mandatoryOnly: Bool, allRecords: [DayRecord], amount: Double? = nil) {
        let streakBeforeAction = streakInfo.currentStreak

        // If discretionary spend and user has streak + freeze available, offer freeze
        if !mandatoryOnly && streakBeforeAction > 0 && hasFreezeAvailable {
            pendingFreezeContext = context
            pendingFreezeRecords = allRecords
            pendingSpendAmount = amount
            previousStreakBeforeBreak = streakBeforeAction
            showFreezeOffer = true
            return
        }

        applySpend(context: context, mandatoryOnly: mandatoryOnly, allRecords: allRecords, useFrozen: false, amount: amount)
    }

    /// Apply spend after freeze decision
    func applySpend(context: ModelContext, mandatoryOnly: Bool, allRecords: [DayRecord], useFrozen: Bool, amount: Double? = nil) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        let streakBeforeAction = streakInfo.currentStreak

        if let existing = todayRecord {
            existing.didSpend = true
            existing.isMandatoryOnly = mandatoryOnly
            existing.isFrozen = useFrozen
            existing.amount = amount
        } else {
            let record = DayRecord(date: today, didSpend: true, isMandatoryOnly: mandatoryOnly, isFrozen: useFrozen, amount: amount)
            context.insert(record)
            todayRecord = record
        }

        if useFrozen {
            streakFreezeCount -= 1
        }

        do {
            try context.save()
        } catch {
            AppLogger.data.error("Failed to save spend record: \(error.localizedDescription)")
            lastError = "Failed to save your record. Please try again."
            return
        }
        HapticManager.toggle()
        SoftPaywallTracker.shared.trackAction()

        var updated = allRecords.filter { calendar.startOfDay(for: $0.date) != today }
        if let current = todayRecord { updated.append(current) }
        streakInfo = StreakCalculator.calculate(from: updated)

        // Check achievements after spend (for total-count and mandatory-only achievements)
        let totalNoBuyDays = updated.filter(\.isNoBuyDay).count
        AchievementManager.shared.checkAchievements(
            currentStreak: streakInfo.currentStreak,
            totalNoBuyDays: totalNoBuyDays,
            records: updated
        )

        if !mandatoryOnly && !useFrozen && streakBeforeAction > 0 && streakInfo.currentStreak == 0 {
            previousStreakBeforeBreak = streakBeforeAction
            showStreakBreak = true

            Task {
                let manager = NotificationManager()
                await manager.scheduleStreakBreakNotification(previousStreak: streakBeforeAction)
                await manager.scheduleLapsedUserNotification()
            }
        }
    }

    /// Use streak freeze — called when user confirms freeze from the offer sheet
    func useFreeze() {
        guard let context = pendingFreezeContext else { return }
        applySpend(context: context, mandatoryOnly: false, allRecords: pendingFreezeRecords, useFrozen: true, amount: pendingSpendAmount)
        pendingFreezeContext = nil
        pendingFreezeRecords = []
        pendingSpendAmount = nil
    }

    /// Decline streak freeze — proceed with normal streak break
    func declineFreeze() {
        guard let context = pendingFreezeContext else { return }
        applySpend(context: context, mandatoryOnly: false, allRecords: pendingFreezeRecords, useFrozen: false, amount: pendingSpendAmount)
        pendingFreezeContext = nil
        pendingFreezeRecords = []
        pendingSpendAmount = nil
    }

    // MARK: - Challenge Management

    func startChallenge(duration: Int) {
        challengeDuration = duration
        challengeStartDate = Calendar.current.startOfDay(for: .now)
        HapticManager.noBuySuccess()
    }

    func clearChallenge() {
        challengeDuration = 0
        challengeStartDate = nil
    }

    func requestNotificationPermission() {
        Task {
            let manager = NotificationManager()
            await manager.requestAuthorization()
        }
    }

    /// Dismiss current error
    func dismissError() {
        lastError = nil
    }
}
