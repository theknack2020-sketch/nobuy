import Foundation

// MARK: - Localization Keys
// All user-facing strings — English only

enum L10n {
    // MARK: - Tabs
    static let tabToday = "Today"
    static let tabCalendar = "Calendar"
    static let tabStats = "Stats"
    static let tabSettings = "Settings"

    // MARK: - Home
    static let appTitle = "NoBuy"
    static let dayStreak = "day streak"
    static func longestStreak(_ days: Int) -> String {
        "Best: \(days) days"
    }
    static let noBuyButton = "I Didn't Spend Today"
    static let noBuyDone = "No Spending ✓"
    static let spentButton = "I spent today"
    static let noRecordYet = "No record yet today"
    static let noBuyToday = "No spending today! 💪"
    static let spentToday = "You spent today"
    static let thisMonth = "This Month"
    static func monthSummary(_ noBuy: Int, _ total: Int) -> String {
        "/ \(total) days no-spend"
    }

    // MARK: - Spend Options
    static let spendTypeQuestion = "What kind of spending?"
    static let mandatorySpend = "Essential Only"
    static let mandatoryDesc = "Rent, bills, transport — streak preserved"
    static let discretionarySpend = "Discretionary"
    static let discretionaryDesc = "Dining, shopping, entertainment"
    static let cancel = "Cancel"

    // MARK: - Calendar
    static let calendarTitle = "Calendar"
    static let summary = "Summary"
    static let noBuyDays = "No-Spend"
    static let spentDays = "Spent"
    static let unrecordedDays = "Unrecorded"

    // MARK: - Settings
    static let settingsTitle = "Settings"
    static let mandatoryCategories = "Essential Expenses"
    static let mandatoryCategoriesFooter = "Spending in these categories won't break your streak."
    static let addCategory = "Add Category"
    static let newCategory = "New Category"
    static let categoryName = "Category name"
    static let add = "Add"
    static let reminders = "Reminders"
    static let notifications = "Notifications"
    static let dailyReminder = "Daily Reminder"
    static let dailyReminderFooter = "Reminds you to log your day each evening."
    static let streakNotifications = "Streak Notifications"
    static let streakNotificationsFooter = "Get notified when you hit new streak records."
    static let time = "Time"
    static let data = "Data"
    static let deleteAllData = "Delete All Data"
    static let about = "About"
    static let version = "Version"
    static let rateApp = "Rate This App"

    // MARK: - Paywall
    static let paywallTitle = "Power Up Your Habit"
    static let paywallSubtitle = "Unlock all features"
    static let paywallPriceAnchor = "Less than one impulse buy"
    static let paywallFeature1 = "Enhanced streak sharing cards"
    static let paywallFeature2 = "Unlimited essential categories"
    static let paywallFeature3 = "Export your data as CSV"
    static func paywallUnlock(_ price: String) -> String {
        "Go Pro — \(price)"
    }
    static let paywallRestore = "Restore Purchase"
    static let paywallWelcome = "Welcome to Pro! 🎉"
    static let paywallWelcomeDetail = "All features are now yours"
    static let paywallRestoreSuccess = "Purchase restored ✓"
    static let paywallRestoreFail = "No purchase found to restore"
    static let proBadge = "PRO"
    static let upgradeButton = "Go Pro"
    static let categoryLimitReached = "Free version allows up to 3 categories."

    // MARK: - Paywall Errors
    static let purchaseErrorGeneric = "Purchase failed. Please try again."
    static let purchaseErrorNetwork = "Check your internet connection and try again."
    static let purchaseErrorNotAllowed = "Purchases not allowed. Check your settings."

    // MARK: - Soft Paywall / Milestones
    static func milestonePaywallMessage(_ days: Int) -> String {
        "Celebrate your \(days)-day streak — unlock more with Pro!"
    }

    // MARK: - Settings Pro
    static let proFeaturesSection = "Pro Features"
    static let proFeatureActive = "Active"
    static let exportCSV = "Export Data (CSV)"
    static let exportCSVProRequired = "CSV export is available with Pro"
    static let enhancedSharing = "Enhanced Sharing Cards"
    static let unlimitedCategories = "Unlimited Categories"

    // MARK: - Onboarding
    static let onboardingTitle1 = "Take Control of Your Spending"
    static let onboardingDesc1 = "Every impulse buy steals from your dreams. Build mindful spending habits with NoBuy."
    static let onboardingTitle2 = "One Tap, Every Day"
    static let onboardingDesc2 = "At the end of each day, tap one button: did you spend or not? That simple."
    static let onboardingTitle3 = "Grow Your Streak, Earn Rewards"
    static let onboardingDesc3 = "Consecutive no-spend days build your streak. Hit milestones, unlock achievements, and feel proud."
    static let onboardingTitle4 = "Set Your Goal"
    static let onboardingDesc4 = "What are you saving for? Starting with a goal multiplies your motivation."
    static let onboardingTitle5 = "Stay on Track with Reminders"
    static let onboardingDesc5 = "Evening reminders so you never forget to log your day and protect your streak."
    static let getStarted = "Get Started"
    static let next = "Next"
    static let skip = "Skip"
    static let enableNotifications = "Enable Notifications"
    static let maybeLater = "Maybe Later"

    // MARK: - Onboarding Goal Options
    static let goalQuestion = "What are you saving for?"
    static let goalEmergencyFund = "Emergency Fund"
    static let goalVacation = "Vacation"
    static let goalDebtFree = "Debt-Free Life"
    static let goalDiscipline = "Just Discipline"
    static let goalCustom = "My Own Goal"
    static let goalCustomPlaceholder = "Type your goal..."
    static let dailySpendingLabel = "How much do you spend daily?"
    static let dailySpendingPlaceholder = "$0"
    static let dailySpendingHint = "We'll use this to calculate your savings."
    static let optional = "optional"

    // MARK: - Streak Break (Compassionate)
    static let streakBreakTitle = "Streak ended"
    static let streakBreakRestart = "Start New Streak"
    static let streakBreakPrevious = "Last streak"
    static let streakBreakLongest = "Best"
    static let streakBreak1 = "One day doesn't change everything. Tomorrow is a fresh start."
    static let streakBreak2 = "Falling isn't failing — getting back up is what matters."
    static let streakBreak3 = "Progress, not perfection. Keep going."
    static let streakBreak4 = "One step back, two steps forward. Tomorrow is a new day."
    static let streakBreak5 = "Be kind to yourself. Every new day is a new chance."
    static func streakBreakWithDays(_ days: Int) -> String {
        "You were strong for \(days) days. That's still an achievement."
    }

    // MARK: - Achievement Titles & Descriptions
    static let achievementFirstDay = "First Step"
    static let achievementFirstDayDesc = "Log your first no-spend day"
    static let achievement3Day = "3-Day Warrior"
    static let achievement3DayDesc = "3 consecutive no-spend days"
    static let achievement7Day = "Week Champion"
    static let achievement7DayDesc = "7 consecutive no-spend days"
    static let achievement14Day = "Two-Week Master"
    static let achievement14DayDesc = "14 consecutive no-spend days"
    static let achievement30Day = "Month Legend"
    static let achievement30DayDesc = "30 consecutive no-spend days"
    static let achievement60Day = "Iron Will"
    static let achievement60DayDesc = "60 consecutive no-spend days"
    static let achievement100Day = "100-Day Club"
    static let achievement100DayDesc = "100 consecutive no-spend days"
    static let achievement365Day = "Year Hero"
    static let achievement365DayDesc = "365 consecutive no-spend days"
    static let achievementTotal30 = "30 Days Total"
    static let achievementTotal30Desc = "30 no-spend days in total"
    static let achievementTotal100 = "Hundredth Day"
    static let achievementTotal100Desc = "100 no-spend days in total"
    static let achievementPerfectWeek = "Perfect Week"
    static let achievementPerfectWeekDesc = "No spending on all 7 days of a week"
    static let achievementPerfectMonth = "Perfect Month"
    static let achievementPerfectMonthDesc = "No spending on every day of a month"

    // MARK: - Milestone Celebrations
    static let milestoneDaysStreak = "day streak"
    static let milestoneContinue = "Continue"
    static let milestone1Title = "First Step!"
    static let milestone1Desc = "The journey begins. Every long road starts with a single step."
    static let milestone3Title = "3 Days Done!"
    static let milestone3Desc = "A habit is forming. You're doing great!"
    static let milestone7Title = "One Week!"
    static let milestone7Desc = "A full week! You've proven your willpower."
    static let milestone14Title = "Two Weeks!"
    static let milestone14Desc = "Two weeks strong. This is becoming a lifestyle."
    static let milestone30Title = "One Month!"
    static let milestone30Desc = "30 days! You're a savings machine."
    static let milestone60Title = "60 Days!"
    static let milestone100Title = "100 Days!"
    static func milestoneGenericTitle(_ days: Int) -> String {
        "\(days) Days!"
    }
    static let milestoneGenericDesc = "Incredible achievement! Keep going."

    // MARK: - Notification Text
    static let notifStreakDaySuffix = "Days!"
    static let notifStreak1 = "Your first no-spend day — great start!"
    static let notifStreak3 = "3 days in a row! A habit is forming."
    static let notifStreak7 = "One week no-spend! You're on fire 🎯"
    static let notifStreak14 = "2-week streak! It's a lifestyle now 💪"
    static let notifStreak30 = "30 days! Legend. You're a savings machine 🏆"
    static let notifStreak60 = "60 days! Two months strong. Incredible 🌟"
    static let notifStreak90 = "90 days! A quarter year no-spend. Legendary 🏅"
    static let notifStreak100 = "💯 100 days! A true milestone!"
    static let notifStreak180 = "Half a year streak! 180 days of discipline 🎖️"
    static let notifStreak365 = "🎉 ONE YEAR! 365 days no-spend. Unbelievable!"
    static let notifDailyReminder1 = "Don't forget to log today! 💪"
    static let notifDailyReminder2 = "Did you spend today? Update your log 📝"
    static let notifDailyReminder3 = "Check your streak — every day counts 🔥"
    static let notifDailyReminder4 = "How was your mindful spending day? Log it ✅"
    static let notifDailyReminder5 = "Another day done. Was it a NoBuy day? 🤔"
    static let notifDailyReminder6 = "Small steps, big changes. Log today 🌱"
    static let notifDailyReminder7 = "Don't forget your spending log! We're waiting 💚"
    static let notifApproachingBestTitle = "1 day from your record! 🏆"
    static let notifStreakBreakTitle = "Streak ended"
    static let notifStreakBreak1 = "One day doesn't change everything. Tomorrow is a fresh start."
    static let notifStreakBreak2 = "You were strong. That's still an achievement."
    static let notifStreakBreak3 = "Falling isn't failing. Tomorrow's with you 💚"
    static let notifWeeklySummaryTitle = "Weekly Summary 📊"
    static let notifWeeklySummaryBody = "Open NoBuy to see this week's performance."
    static let notifLapsed1 = "We miss you! How about logging today? 💚"
    static let notifLapsed2 = "No records for 2 days. Protect your streak! 🔥"
    static let notifLapsed3 = "Great day to come back. We're waiting 🌱"

    // MARK: - Data Export
    static let exportTitle = "Data Export"
    static let exportSuccess = "Data exported successfully."
    static let exportFailed = "Export failed. Please try again."
    static let exportEmpty = "No data to export."
    static let exportColumnDate = "Date"
    static let exportColumnStatus = "Status"
    static let exportColumnMandatory = "Essential Only"
    static let exportColumnAmount = "Amount"
    static let exportColumnNote = "Note"

    // MARK: - Tips / Facts (rotating daily)
    static let tip1 = "The average person makes 12 impulse purchases per month."
    static let tip2 = "The 24-hour rule: Wait 24 hours before buying something you want."
    static let tip3 = "Shopping with a list reduces spending by 23%."
    static let tip4 = "52% of impulse purchases lead to regret."
    static let tip5 = "Every no-spend day is one step closer to financial freedom."
    static let tip6 = "Small savings add up. $10/day = $3,650/year."
    static let tip7 = "Before buying, ask: 'Do I really need this?'"
    static let tip8 = "Instead of stress shopping, take a 10-minute walk."
    static let tip9 = "Turn off notifications from shopping apps."
    static let tip10 = "Celebrate every streak record — reward yourself (without spending!)."
    static let tip11 = "Take 3 deep breaths before spending. The urge usually passes."
    static let tip12 = "Remove your credit card from your wallet. Carry cash only."
    static let tip13 = "Unsubscribe from marketing emails. Out of sight, out of mind."
    static let tip14 = "Every dollar not spent is a dollar invested in your future self."
    static let tip15 = "Track your urges, not just your spending. Awareness is power."
    static let tip16 = "The things you own end up owning you. Choose freedom."
    static let tip17 = "Wait 30 days for big purchases. If you still want it, it's real."
    static let tip18 = "Replace retail therapy with a walk, a book, or a call with a friend."
    static let tip19 = "Your future self will thank you for every no-spend day."
    static let tip20 = "Boredom isn't a reason to shop. Find a free hobby instead."

    // MARK: - Share Card
    static let shareStreakDays = "DAY STREAK"
    static func shareSince(_ date: String) -> String {
        "Since \(date)"
    }
    static let shareThisMonth = "This Month"
    static let shareLongest = "Best"
    static let shareNoBuy = "NoBuy — Mindful Spending"
    static let shareJoinMe = "Join me!"

    // MARK: - Empty States
    static let emptyHomeTitle = "No records yet"
    static let emptyHomeDesc = "Tap the button to log your first no-spend day."
    static let emptyCalendarTitle = "Calendar is empty"
    static let emptyCalendarDesc = "Start logging days to see your calendar light up."
    static let emptyAchievementsTitle = "No achievements yet"
    static let emptyAchievementsDesc = "Build no-spend days to unlock achievements."
    static let emptyStreakTitle = "No streak"
    static let emptyStreakDesc = "Log your first no-spend day to start your streak!"

    // MARK: - Settings Extra
    static let settingsAppIcon = "App Icon"
    static let settingsCurrentIcon = "Default"
    static let settingsMoreIconsSoon = "New icons coming soon!"
    static let settingsPrivacy = "Privacy"
    static let settingsPrivacyNote = "All your data stays on this device only. Nothing is sent to any server."
    static let settingsBuild = "Build"

    // MARK: - Privacy & Legal
    static let privacyLegalSection = "Privacy & Legal"
    static let privacyPolicy = "Privacy Policy"
    static let termsOfUse = "Terms of Use"

    // MARK: - Stats Pro Badge
    static let proFeature = "PRO"

    // MARK: - Spend Amount
    static let spendAmountPlaceholder = "Amount (optional)"

    // MARK: - Mandatory Categories (localized defaults)
    static let categoryRent = "Rent"
    static let categoryBills = "Bills"
    static let categoryTransport = "Transport"
    static let categoryGroceries = "Groceries"

    // MARK: - Delete Confirmation
    static let deleteConfirmTitle = "Are you sure?"
    static let deleteConfirmMessage = "All data will be permanently deleted. This cannot be undone."
    static let deleteConfirmButton = "Delete"

    // MARK: - Error Messages
    static let errorGenericTitle = "Something Went Wrong"
    static let errorGenericMessage = "Please try again. If the problem persists, restart the app."
    static let errorSaveTitle = "Couldn't Save"
    static let errorSaveMessage = "Your data couldn't be saved. Please try again."
    static let errorLoadTitle = "Couldn't Load Data"
    static let errorLoadMessage = "There was a problem loading your data. Please restart the app."
    static let errorExportTitle = "Export Failed"
    static let errorExportMessage = "Couldn't create the export file. Please try again."
    static let errorOK = "OK"
    static let errorRetry = "Retry"

    // MARK: - Form Validation
    static let validationRequired = "This field is required"
    static let validationMinDays = "Minimum 1 day"
    static let validationMaxDays = "Maximum 365 days"
    static let validationNumberOnly = "Enter a valid number"

    // MARK: - Empty State Micro-Copy
    static let emptyWaitingListTitle = "Your Waiting List is Empty"
    static let emptyWaitingListDesc = "Next time you want to buy something, add it here first. Most impulses fade within 24 hours."
    static let emptyWaitingListCTA = "Add First Item"
    static let emptyAchievementsSubtitle = "Every streak unlocks a new badge. Start your first no-spend day!"
    static let emptyStatsTitle = "No Stats Yet"
    static let emptyStatsDesc = "Start logging your days to see trends, streaks, and insights here."
    static let emptyCalendarSubtitle = "Your calendar is a blank canvas. Paint it green with no-spend days!"
}
