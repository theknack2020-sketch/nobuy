import Foundation
import SwiftData

#if DEBUG
    /// Deterministic demo dataset for the store-screenshot pipeline. Seeds an
    /// in-memory SwiftData store plus the UserDefaults the Home/Stats story
    /// reads, and silences every interruption (onboarding, What's New, tips,
    /// rating card) so frames come out clean. Never compiled into Release.
    @MainActor
    enum DemoSeeder {
        /// Pure factory: ~90 days of records ending today, no randomness.
        /// - Days 0–22 back: no-spend → a live 23-day streak.
        /// - Day 23 back: discretionary spend ($34.99) — the streak boundary.
        /// - Day 30 back: a frozen day (shield state in the calendar legend).
        /// - Days 24–59 back: Saturdays slip + two essential-only days.
        /// - Days 60–89 back: Tuesdays and Saturdays spend — the rough start,
        ///   so the monthly trend chart climbs month over month.
        static func makeRecords(today: Date = .now, calendar: Calendar = .current) -> [DayRecord] {
            let startOfToday = calendar.startOfDay(for: today)
            var records: [DayRecord] = []

            for daysAgo in 0 ... 89 {
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: startOfToday)
                else { continue }

                switch daysAgo {
                case 0 ... 22:
                    let note: String? = switch daysAgo {
                    case 2: "Skipped the flash sale 💪"
                    case 9: "Left the cart overnight"
                    case 16: "Coffee at home instead"
                    default: nil
                    }
                    records.append(DayRecord(date: date, didSpend: false, note: note))
                case 23:
                    records.append(DayRecord(date: date, didSpend: true, amount: 34.99))
                case 30:
                    records.append(DayRecord(date: date, didSpend: true, isFrozen: true))
                case 24 ... 59:
                    let weekday = calendar.component(.weekday, from: date)
                    if weekday == 7 {
                        records.append(DayRecord(date: date, didSpend: true, amount: 19.99))
                    } else if daysAgo == 40 || daysAgo == 47 {
                        records.append(DayRecord(date: date, didSpend: true, isMandatoryOnly: true))
                    } else {
                        records.append(DayRecord(date: date, didSpend: false))
                    }
                default:
                    let weekday = calendar.component(.weekday, from: date)
                    if weekday == 3 || weekday == 7 {
                        records.append(DayRecord(date: date, didSpend: true, amount: 24.50))
                    } else {
                        records.append(DayRecord(date: date, didSpend: false))
                    }
                }
            }
            return records
        }

        /// Seeds the (in-memory) store and UserDefaults for a screenshot run.
        static func seed(into container: ModelContainer) {
            let context = container.mainContext
            let records = makeRecords()
            for record in records {
                context.insert(record)
            }
            for (name, icon) in MandatoryCategory.defaults {
                context.insert(MandatoryCategory(name: name, icon: icon))
            }
            try? context.save()

            let defaults = UserDefaults.standard
            // A coherent Home/Stats story: ~$575 saved, challenge 23/30 mid-run.
            defaults.set(25.0, forKey: "dailySpendingEstimate")
            defaults.set("Vacation fund", forKey: "savingsGoal")
            defaults.set(30, forKey: "challengeDuration")
            let startOfToday = Calendar.current.startOfDay(for: .now)
            let challengeStart = Calendar.current.date(byAdding: .day, value: -22, to: startOfToday)
                ?? startOfToday
            defaults.set(challengeStart.timeIntervalSince1970, forKey: "challengeStartDate")
            defaults.set(1, forKey: "streakFreezeCount")
            defaults.set(true, forKey: "hasSeededDefaults")
            defaults.set(true, forKey: "hasCompletedOnboarding")
            defaults.set(12, forKey: "launchCount")

            // Silence every interruption that could pollute a frame.
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            defaults.set(version, forKey: "lastSeenVersion")
            defaults.set(Date.now.timeIntervalSince1970, forKey: "lastRatingPromptDate")

            // Pro immediately and deterministically — checkEntitlements is gated
            // behind a StoreKit product load that can take seconds on a cold
            // simctl launch, and screenshot panels must show unlocked value.
            StoreService.shared.forceProForDemo()

            // Derive achievement unlocks organically, then clear the celebration
            // so no modal fires on launch.
            let manager = AchievementManager.shared
            manager.resetForTesting()
            let streakInfo = StreakCalculator.calculate(from: records)
            manager.checkAchievements(
                currentStreak: streakInfo.currentStreak,
                totalNoBuyDays: records.filter(\.isNoBuyDay).count,
                records: records
            )
            manager.clearNewlyUnlocked()
        }
    }
#endif
