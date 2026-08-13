import os
import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import UserNotifications

struct SettingsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreService.self) private var store
    @Query private var mandatoryCategories: [MandatoryCategory]
    @Query(sort: \DayRecord.date, order: .reverse) private var records: [DayRecord]
    @State private var showAddCategory = false
    @State private var showDeleteConfirmation = false
    @State private var showPaywall = false
    @State private var paywallEntry: PaywallEntry = .general
    @State private var showCategoryLimit = false
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var newCategoryName = ""
    @State private var showChallengeSetup = false
    @AppStorage("hasSeededDefaults") private var hasSeededDefaults = false
    @AppStorage("launchCount") private var launchCount = 0
    @AppStorage("streakFreezeCount") private var streakFreezeCount = 1
    @AppStorage("challengeDuration") private var challengeDuration = 0
    @AppStorage("challengeStartDate") private var challengeStartDate: Double = 0
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("savingsGoal") private var savingsGoal: String = ""
    @AppStorage("dailySpendingEstimate") private var dailySpendingEstimate: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Settings Header

                // MARK: - Standing
                //
                // Three people can read this screen and each gets their own first section:
                // an EARLY SUPPORTER (one of the 60 who bought the retired lifetime unlock),
                // a subscriber, and someone on the free tier. The crown, the pulsing glow and
                // the gradient button are gone — the tokens forbid gradient-as-decoration and
                // crown imagery, and none of them told the user anything a sentence could not.

                Section {
                    if store.isLegacyLifetimeOwner {
                        earlySupporterRow
                    } else if store.isPro {
                        subscriberRow
                    } else {
                        freeStandingRow
                    }
                }

                // MARK: - Pro Features

                if store.isPro {
                    proFeaturesSection
                }

                // MARK: - Mandatory Categories

                Section {
                    ForEach(mandatoryCategories) { category in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundStyle(.stateWait)
                                .frame(width: 28)
                                .accessibilityHidden(true)
                            Text(category.name)
                        }
                    }
                    .onDelete(perform: deleteCategories)

                    Button {
                        if store.canAddCategory(currentCount: mandatoryCategories.count) {
                            showAddCategory = true
                        } else {
                            showCategoryLimit = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(.accentKept)
                            Text(L10n.addCategory)
                            if !store.isPro {
                                Spacer()
                                Text("\(mandatoryCategories.count)/\(StoreService.freeCategoryLimit)")
                                    .font(.caption)
                                    .foregroundStyle(.inkSecondary)
                            }
                        }
                    }
                    .buttonStyle(.scale)
                    .accessibilityLabel("Add essential category")
                } header: {
                    Text(L10n.mandatoryCategories)
                } footer: {
                    Text(L10n.mandatoryCategoriesFooter)
                }

                // MARK: - Streak

                Section {
                    HStack {
                        Image(systemName: "shield")
                            .foregroundStyle(.accentKept)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Streak Freeze")
                                .font(.body)
                            Text("Protects your streak when you spend")
                                .font(.caption)
                                .foregroundStyle(.inkSecondary)
                        }
                        Spacer()
                        Text(freezeDisplayText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.accentKept)
                    }

                    HStack {
                        Image(systemName: "snowflake")
                            .foregroundStyle(Color.stateWait)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        Text("Monthly Freeze Allowance")
                        Spacer()
                        Text(store.isPro
                            ? "Unlimited"
                            : "1 / month")
                            .font(.callout)
                            .foregroundStyle(.inkSecondary)
                    }
                } header: {
                    Text("Streak")
                } footer: {
                    Text("Freeze preserves your streak for one day when you make discretionary spending. Free users get 1/month, Pro users get unlimited.")
                }

                // MARK: - Challenge

                Section {
                    if challengeDuration > 0, challengeStartDate > 0 {
                        let startDate = Date(timeIntervalSince1970: challengeStartDate)
                        let elapsed = Calendar.current.dateComponents([.day], from: startDate, to: .now).day ?? 0
                        let completed = min(elapsed, challengeDuration)
                        let remaining = max(challengeDuration - completed, 0)
                        let isCompleted = completed >= challengeDuration

                        HStack {
                            Image(systemName: isCompleted ? "trophy.fill" : "flame.fill")
                                .foregroundStyle(isCompleted ? .stateWait : .accentKept)
                                .frame(width: 28)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(challengeDuration)-Day Challenge")
                                    .font(.body)
                                if isCompleted {
                                    Text("Completed")
                                        .font(.caption)
                                        .foregroundStyle(.stateWait)
                                } else {
                                    Text("\(remaining) days left")
                                        .font(.caption)
                                        .foregroundStyle(.inkSecondary)
                                }
                            }
                            Spacer()
                            Text("\(completed)/\(challengeDuration)")
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundStyle(.accentKept)
                        }
                    }

                    Button {
                        showChallengeSetup = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(.accentKept)
                                .frame(width: 28)
                                .accessibilityHidden(true)
                            Text(challengeDuration > 0
                                ? "Start New Challenge"
                                : "Start Challenge")
                        }
                    }
                    .buttonStyle(.scale)
                } header: {
                    Text("Challenge")
                } footer: {
                    Text("Set yourself a goal and see how many no-spend days you can achieve.")
                }

                // MARK: - Savings goal
                //
                // v2.0.0 moved this OUT of onboarding: setup is now four screens and one real
                // question, and a goal picker standing between a new user and their first
                // answer cost more than it earned. But a feature with no way to reach it is an
                // orphan (finished-product law, clause 6), so it lives here — optional, changeable,
                // and ignorable.

                Section {
                    Picker(selection: $savingsGoal) {
                        Text("Not set").tag("")
                        Text("Emergency fund").tag("emergencyFund")
                        Text("A trip").tag("vacation")
                        Text("Getting out of debt").tag("debtFree")
                        Text("Just the discipline").tag("discipline")
                    } label: {
                        HStack {
                            Image(systemName: "target")
                                .foregroundStyle(.stateWait)
                                .frame(width: 28)
                            Text("What you're saving for")
                        }
                    }
                    .accessibilityIdentifier("settings_savings_goal")

                    HStack {
                        Image(systemName: "banknote")
                            .foregroundStyle(.stateWait)
                            .frame(width: 28)
                        Text("A typical spend day")
                        Spacer()
                        TextField("optional", value: $dailySpendingEstimate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 90)
                            .accessibilityLabel("Typical spending on a day you buy something")
                    }
                } header: {
                    Text("Goal")
                } footer: {
                    Text("Both are optional. They only change the estimate shown on Stats — the record itself never depends on them.")
                }

                // MARK: - Notifications

                Section {
                    Toggle(isOn: $soundEnabled) {
                        HStack {
                            Image(systemName: "speaker.wave.2")
                                .foregroundStyle(.accentKept)
                                .frame(width: 28)
                            Text("Sound Effects")
                        }
                    }
                    .tint(.accentKept)
                    .accessibilityLabel("Sound effects")
                    .accessibilityValue(soundEnabled ? "On" : "Off")
                    .accessibilityHint("Double tap to toggle sound effects")

                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundStyle(.accentKept)
                                .frame(width: 28)
                            Text(L10n.notifications)
                        }
                    }
                    .accessibilityLabel("Notification settings")
                    .accessibilityHint("Double tap to configure reminders")
                } header: {
                    Text(L10n.reminders)
                }

                // MARK: - Data

                Section {
                    Button {
                        // Free, deliberately: a record you cannot take with you is a record
                        // held hostage, and the free tier's own promise is that it is not
                        // (docs/FREE-TIER.md). Export is what makes the 90-day view window an
                        // honest limit rather than a lock on the user's own data.
                        exportCSV()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down.doc")
                                .foregroundStyle(.accentKept)
                                .frame(width: 28)
                                .accessibilityHidden(true)
                            Text(L10n.exportCSV)
                            Spacer()
                            // No PRO badge, on purpose. The button above runs for everyone, the
                            // free-tier map says export is free, the paywall lists it as free and
                            // the store description sells it as free — a badge here was the one
                            // surface still claiming otherwise, and a lock on a button that is
                            // not locked reads as a bait.
                        }
                    }
                    .buttonStyle(.scale)
                    .accessibilityLabel("Export data as CSV")

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .frame(width: 28)
                            Text(L10n.deleteAllData)
                        }
                    }
                    .accessibilityLabel("Delete all data")
                    .accessibilityHint("Double tap to permanently delete all records")
                } header: {
                    Text(L10n.data)
                }

                // MARK: - Appearance

                Section {
                    ThemePickerView(showPaywall: $showPaywall, entry: $paywallEntry)
                } header: {
                    Text("Appearance")
                }

                // MARK: - About

                Section {
                    HStack {
                        Text(L10n.version)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.inkSecondary)
                    }

                    HStack {
                        Text(L10n.settingsBuild)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundStyle(.inkSecondary)
                    }

                    // User-initiated ask: deep-link straight to the App Store
                    // review form — the native prompt API is rate-limited and
                    // can silently no-op on an explicit tap.
                    Link(destination: URL(string: "https://apps.apple.com/app/id6760716822?action=write-review")!) {
                        HStack {
                            Image(systemName: "star")
                                .foregroundStyle(.accentSpentMark)
                                .frame(width: 28)
                            Text(L10n.rateApp)
                        }
                    }
                    .buttonStyle(.scale)
                    .accessibilityLabel("Rate NoBuy on the App Store")
                    .accessibilityHint("Double tap to leave a review")
                } header: {
                    Text(L10n.about)
                }

                // MARK: - Privacy

                Section {
                    HStack(spacing: DS.Spacing.md) {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(.accentKept)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            Text(L10n.settingsPrivacy)
                                .font(.body)
                            Text(L10n.settingsPrivacyNote)
                                .font(.caption)
                                .foregroundStyle(.inkSecondary)
                        }
                    }
                } header: {
                    Text(L10n.settingsPrivacy)
                }

                // MARK: - Privacy & Legal

                Section {
                    Link(destination: URL(string: "https://theknack2020-sketch.github.io/nobuy/privacy/")!) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundStyle(.accentKept)
                                .frame(width: 28)
                            Text(L10n.privacyPolicy)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.inkSecondary)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityLabel("Privacy Policy")
                    .accessibilityHint("Opens privacy policy in browser")

                    Link(destination: URL(string: "https://theknack2020-sketch.github.io/nobuy/terms/")!) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundStyle(.accentKept)
                                .frame(width: 28)
                            Text(L10n.termsOfUse)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.inkSecondary)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityLabel("Terms of Use")
                    .accessibilityHint("Opens terms of use in browser")
                } header: {
                    Text(L10n.privacyLegalSection)
                }

                // MARK: - More Apps

                Section {
                    moreAppRow(
                        icon: "drop.fill",
                        name: "AquaFaste",
                        subtitle: "Hydration Tracker",
                        appStoreID: "6760975661"
                    )
                    moreAppRow(
                        icon: "fork.knife",
                        name: "Lumifaste",
                        subtitle: "Fasting Tracker",
                        appStoreID: "6760971357"
                    )
                    moreAppRow(
                        icon: "pills.fill",
                        name: "PillPal",
                        subtitle: "Medication Reminder",
                        appStoreID: "6740510337"
                    )
                    moreAppRow(
                        icon: "pawprint.fill",
                        name: "Vettie",
                        subtitle: "Pet Health Tracker",
                        appStoreID: "6760741400"
                    )
                } header: {
                    Text("More by TheKnack")
                }

                // MARK: - Footer

                Section {} footer: {
                    VStack(spacing: DS.Spacing.xs) {
                        Text("© 2026 TheKnack. All rights reserved.")
                            .font(.caption2)
                            .foregroundStyle(.inkSecondary)
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                            .font(.caption2)
                            .foregroundStyle(.inkSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, DS.Spacing.md)
                    .accessibilityElement(children: .combine)
                }
            }
            .navigationTitle(L10n.settingsTitle)
            .navigationBarTitleDisplayMode(.large)
            .listStyle(.insetGrouped)
            // Settings is one of the four rooms, and until now the only one that let the system's
            // grouped background through — noticeably lighter than the field in light mode and
            // pure black against #0F1113 in dark.
            .scrollContentBackground(.hidden)
            .background(Color.surfaceField)
            .alert(L10n.newCategory, isPresented: $showAddCategory) {
                TextField(L10n.categoryName, text: $newCategoryName)
                Button(L10n.add) {
                    guard !newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let category = MandatoryCategory(name: newCategoryName)
                    modelContext.insert(category)
                    newCategoryName = ""
                }
                Button(L10n.cancel, role: .cancel) { newCategoryName = "" }
            }
            .alert(L10n.categoryLimitReached, isPresented: $showCategoryLimit) {
                Button(L10n.upgradeButton) {
                    paywallEntry = .categoryLimit(
                        used: mandatoryCategories.count,
                        limit: StoreService.freeCategoryLimit
                    )
                    showPaywall = true
                }
                Button(L10n.cancel, role: .cancel) {}
            }
            .alert("Are you sure? All data will be permanently deleted.", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) { resetAllData() }
                Button(L10n.cancel, role: .cancel) {}
            } message: {
                Text("This action cannot be undone. All daily records and streak data will be deleted.")
            }
            .fullScreenCover(isPresented: $showPaywall) { PaywallView(store: store, entry: paywallEntry) }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL { ShareSheet(items: [url]) }
            }
            .sheet(isPresented: $showChallengeSetup) {
                ChallengeSetupSheet { duration in
                    challengeDuration = duration
                    challengeStartDate = Calendar.current.startOfDay(for: .now).timeIntervalSince1970
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .onAppear {
                if !hasSeededDefaults {
                    seedDefaultsIfNeeded()
                }
                trackLaunch()
            }
        }
    }

    // MARK: - Pro Features Section

    private var freezeDisplayText: String {
        if store.isPro {
            return "Unlimited"
        }
        return "\(streakFreezeCount)"
    }

    private var proFeaturesSection: some View {
        Section {
            proFeatureRow(icon: "square.and.arrow.up.fill", title: L10n.enhancedSharing)
            proFeatureRow(icon: "folder.fill.badge.plus", title: L10n.unlimitedCategories)
        } header: { Text(L10n.proFeaturesSection) }
    }

    private func proFeatureRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(.accentKept).frame(width: 28).accessibilityHidden(true)
            Text(title).font(.body)
            Spacer()
            Text(L10n.proFeatureActive).font(.caption).foregroundStyle(.accentKept)
        }
    }

    // MARK: - CSV Export

    private func exportCSV() {
        do {
            let url = try DataExportService.exportCSV(records: records)
            exportURL = url
            showExportSheet = true
        } catch {
            AppLogger.data.error("CSV export error: \(error.localizedDescription)")
            // Show error through existing alert mechanism if available
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(mandatoryCategories[index])
        }
    }

    private func resetAllData() {
        do {
            try modelContext.delete(model: DayRecord.self)
            try modelContext.delete(model: MandatoryCategory.self)
            hasSeededDefaults = false
            seedDefaultsIfNeeded()
            HapticManager.notification(.warning)
        } catch { AppLogger.data.error("Failed to reset data: \(error.localizedDescription)") }
    }

    private func seedDefaultsIfNeeded() {
        guard !hasSeededDefaults else { return }
        for (name, icon) in MandatoryCategory.defaults {
            let category = MandatoryCategory(name: name, icon: icon)
            modelContext.insert(category)
        }
        hasSeededDefaults = true
    }

    private func trackLaunch() {
        launchCount += 1
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}

struct NotificationSettingsView: View {
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = true
    @AppStorage("streakNotificationsEnabled") private var streakNotificationsEnabled = false
    @AppStorage("weeklySummaryEnabled") private var weeklySummaryEnabled = false
    @AppStorage("notificationHour") private var notificationHour = 21
    @AppStorage("notificationMinute") private var notificationMinute = 0
    @Environment(StoreService.self) private var store

    @State private var notificationTime = Date()
    @State private var showPaywall = false
    @State private var notificationsDenied = false

    private func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsDenied = settings.authorizationStatus == .denied
    }

    var body: some View {
        List {
            if notificationsDenied {
                Section {
                    Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
                        HStack(spacing: DS.Spacing.md) {
                            Image(systemName: "bell.slash")
                                .foregroundStyle(.stateWait)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notifications are off in Settings")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.inkPrimary)
                                Text("Open Settings to allow reminders")
                                    .font(.caption)
                                    .foregroundStyle(.inkSecondary)
                            }
                        }
                    }
                    .accessibilityLabel("Notifications are off. Open Settings to allow reminders")
                }
            }

            Section {
                Toggle(L10n.dailyReminder, isOn: $dailyReminderEnabled)
                    .tint(.accentKept)
                    .onChange(of: dailyReminderEnabled) { _, enabled in
                        if enabled {
                            Task {
                                let manager = NotificationManager()
                                await manager.requestAuthorization()
                                await refreshAuthorizationStatus()
                                if notificationsDenied {
                                    // Honest toggle: permission denied means no
                                    // reminder will ever fire.
                                    dailyReminderEnabled = false
                                    return
                                }
                                await manager.scheduleDailyReminder(
                                    hour: notificationHour,
                                    minute: notificationMinute
                                )
                            }
                        } else {
                            NotificationManager().cancelDailyReminder()
                        }
                    }

                if dailyReminderEnabled {
                    DatePicker(
                        L10n.time,
                        selection: $notificationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .tint(.accentKept)
                    .onChange(of: notificationTime) { _, newTime in
                        let calendar = Calendar.current
                        notificationHour = calendar.component(.hour, from: newTime)
                        notificationMinute = calendar.component(.minute, from: newTime)

                        Task {
                            let manager = NotificationManager()
                            await manager.scheduleDailyReminder(
                                hour: notificationHour,
                                minute: notificationMinute
                            )
                        }
                    }
                }
            } footer: {
                Text(L10n.dailyReminderFooter)
            }

            Section {
                Toggle(L10n.streakNotifications, isOn: $streakNotificationsEnabled)
                    .tint(.accentKept)
            } footer: {
                Text(L10n.streakNotificationsFooter)
            }

            Section {
                if store.isPro {
                    Toggle(
                        "Weekly Summary",
                        isOn: $weeklySummaryEnabled
                    )
                    .tint(.accentKept)
                    .onChange(of: weeklySummaryEnabled) { _, enabled in
                        Task {
                            let manager = NotificationManager()
                            if enabled {
                                await manager.scheduleWeeklySummary()
                            } else {
                                manager.cancelWeeklySummary()
                            }
                        }
                    }
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Text("Weekly Summary")
                                .foregroundStyle(.inkPrimary)
                            Spacer()
                            Text(L10n.proBadge)
                                .font(.caption2.bold())
                                .foregroundStyle(.accentKept)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.accentKeptWash))
                        }
                    }
                }
            } footer: {
                Text("Sends a weekly performance summary every Sunday evening.")
            }
        }
        .navigationTitle(L10n.notifications)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
            components.hour = notificationHour
            components.minute = notificationMinute
            if let date = Calendar.current.date(from: components) {
                notificationTime = date
            }
        }
        .task {
            await refreshAuthorizationStatus()
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(store: store, entry: .weeklySummary)
        }
    }
}

// MARK: - Theme Picker View

struct ThemePickerView: View {
    @Environment(StoreService.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var showPaywall: Bool
    @Binding var entry: PaywallEntry
    @State private var gridAppeared = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Theme")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.inkSecondary)

            LazyVGrid(columns: columns, spacing: DS.Spacing.md) {
                ForEach(AppTheme.allCases) { theme in
                    ThemeDot(
                        theme: theme,
                        isSelected: UserSettings.shared.currentTheme == theme,
                        isLocked: theme.isPro && !store.isPro
                    ) {
                        if theme.isPro, !store.isPro {
                            entry = .themes
                            showPaywall = true
                        } else {
                            HapticManager.impact(.light)
                            withAnimation(reduceMotion ? nil : DS.Anim.quick) {
                                UserSettings.shared.currentTheme = theme
                            }
                        }
                    }
                }
            }
            .opacity(gridAppeared ? 1 : 0)
            .scaleEffect(gridAppeared ? 1 : 0.95)
            .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8), value: gridAppeared)
            .onAppear { gridAppeared = true }
        }
        .padding(.vertical, DS.Spacing.xs)
    }
}

// MARK: - Theme Dot

private struct ThemeDot: View {
    let theme: AppTheme
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.colorScheme) private var colorScheme

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: DS.Spacing.sm) {
                ZStack {
                    // The swatch IS the finish — a dial face with its bezel, because the finish
                    // is exactly what a theme changes. No gradient: the tokens forbid gradients
                    // as decoration, and a two-colour sweep would imply the accent moves with
                    // the theme, which is the v1 defect this system removes.
                    Circle()
                        .fill(theme.dial(colorScheme))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle().strokeBorder(Color.inkHairline, lineWidth: DS.Stroke.bezel)
                        )

                    // A seated hand, drawn in the one accent that never moves: proof that
                    // meaning survives every finish.
                    Capsule()
                        .fill(Color.accentKept)
                        .frame(width: DS.Stroke.hand, height: 14)
                        .offset(y: -7)

                    if isSelected {
                        Circle()
                            .strokeBorder(Color.accentKept, lineWidth: 2)
                            .frame(width: 52, height: 52)
                    }

                    // Locked finishes are NOT darkened and carry no padlock — deprivation
                    // imagery is banned in this product's surfaces. The row's own "Pro" label
                    // below says it in words instead.
                }

                // Theme name
                Text(theme.displayName)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .inkPrimary : .inkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                // The badge says what this finish COSTS, so it belongs only to someone who has
                // not paid. A subscriber was still seeing "PRO" stamped under four finishes they
                // already own — the row telling them they cannot have the thing they are using.
                if theme.isPro, isLocked {
                    Text("PRO")
                        .font(Font.adaptiveCaption2(isRegular: isRegular).weight(.bold))
                        .foregroundStyle(.accentKept)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            Capsule().fill(Color.accentKeptWash)
                        )
                } else {
                    // Spacer for alignment
                    Text(" ")
                        .font(Font.adaptiveCaption2(isRegular: isRegular))
                        .padding(.vertical, 1)
                        .opacity(0)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.displayName) theme\(isLocked ? ", locked, requires Pro" : "")\(isSelected ? ", selected" : "")")
    }
}

// MARK: - Standing
//
// Three people can read this screen and each gets their own first section: an EARLY SUPPORTER
// (one of the 60 who bought the retired lifetime unlock), a subscriber, and someone on the free
// tier.

extension SettingsScreen {
    /// The 60 people who bought the retired one-time unlock.
    ///
    /// Their purchase is honoured permanently and this is where they are told so, in the FIRST
    /// section of Settings — "Early supporter", never "expired" or "legacy". They are never
    /// shown the paywall; `StoreService.checkEntitlements()` reads their old receipt on every
    /// launch and grants everything Pro grants.
    ///
    /// This row exists because a promise kept silently is a promise the customer cannot see.
    var earlySupporterRow: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("Early supporter")
                .font(.headline)
                .foregroundStyle(.inkPrimary)

            Text("You bought NoBuy Pro outright, before it became a subscription. It stays yours — permanently, with nothing to renew and nothing to cancel.")
                .font(.subheadline)
                .foregroundStyle(.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, DS.Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("settings_early_supporter")
    }

    var subscriberRow: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("NoBuy Pro")
                .font(.headline)
                .foregroundStyle(.inkPrimary)

            Text("Every day on record, the analysis, challenges, and all five finishes. Manage or cancel any time in Settings ▸ Subscriptions.")
                .font(.subheadline)
                .foregroundStyle(.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, DS.Spacing.sm)
        .accessibilityElement(children: .combine)
    }

    /// The free tier's own row: what it holds, stated plainly, with the door beside it rather
    /// than in place of it.
    var freeStandingRow: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("NoBuy")
                .font(.headline)
                .foregroundStyle(.inkPrimary)

            Text("The nightly question, your run, the freeze, both interventions and every widget — free, always. Pro opens the whole record and the analysis behind it.")
                .font(.subheadline)
                .foregroundStyle(.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                showPaywall = true
            } label: {
                Text("See NoBuy Pro")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.inkOnAccent)
                    .padding(.horizontal, DS.Spacing.xl)
                    .frame(height: 44)
                    .background(Capsule().fill(Color.accentKept))
            }
            .buttonStyle(.scale)
            .accessibilityHint("Opens plans and pricing")
            .accessibilityIdentifier("settings_upgrade_pro")
        }
        .padding(.vertical, DS.Spacing.sm)
    }
}

// MARK: - More App Row Helper

extension SettingsScreen {
    func moreAppRow(icon: String, name: String, subtitle: String, appStoreID: String) -> some View {
        Button {
            HapticManager.tap()
            if let url = URL(string: "itms-apps://apple.com/app/id\(appStoreID)") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: DS.Spacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.accentKept)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(name), \(subtitle)")
        .accessibilityHint("Opens in App Store")
    }
}

#Preview {
    SettingsScreen()
        .environment(StoreService.shared)
        .modelContainer(for: [DayRecord.self, MandatoryCategory.self], inMemory: true)
}
