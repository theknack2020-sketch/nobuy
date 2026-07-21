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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Settings Header

                Section {
                    VStack(spacing: DS.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.noBuyGreen.opacity(0.3), Color.clear],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 100, height: 100)

                            Group {
                                if store.isPro {
                                    Image(systemName: "crown.fill")
                                        .font(Font.adaptiveDisplay(size: 36, isRegular: isRegular))
                                        .foregroundStyle(Color.noBuyGreen)
                                } else {
                                    ZStack {
                                        Image(systemName: "bag.fill")
                                            .font(Font.adaptiveDisplay(size: 32, weight: .medium, isRegular: isRegular))
                                            .accessibilityHidden(true)
                                        Image(systemName: "line.diagonal")
                                            .font(Font.adaptiveDisplay(size: 40, isRegular: isRegular))
                                            .accessibilityHidden(true)
                                    }
                                    .foregroundStyle(.textSecondary)
                                }
                            }
                            .symbolEffect(.pulse, options: .repeating)
                        }

                        Text(store.isPro ? "NoBuy Pro" : "NoBuy")
                            .font(.title2.bold())

                        if !store.isPro {
                            Button {
                                showPaywall = true
                            } label: {
                                Text("Upgrade to Pro")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, DS.Spacing.xl)
                                    .padding(.vertical, DS.Spacing.sm)
                                    .background(
                                        Capsule().fill(
                                            LinearGradient(
                                                colors: [Color.noBuyGreen, Color.noBuyGreen.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    )
                                    .shadow(color: .noBuyGreen.opacity(0.3), radius: 8, y: 4)
                            }
                            .buttonStyle(.scale)
                            .accessibilityLabel("Upgrade to Pro")
                            .accessibilityHint("Double tap to view Pro features and pricing")
                            .accessibilityIdentifier("settings_upgrade_pro")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.lg)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
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
                                .foregroundStyle(.mandatoryAmber)
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
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.noBuyGreen)
                            Text(L10n.addCategory)
                            if !store.isPro {
                                Spacer()
                                Text("\(mandatoryCategories.count)/\(StoreService.freeCategoryLimit)")
                                    .font(.caption)
                                    .foregroundStyle(.textTertiary)
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
                        Image(systemName: "shield.fill")
                            .foregroundStyle(.noBuyGreen)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Streak Freeze")
                                .font(.body)
                            Text("Protects your streak when you spend")
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                        }
                        Spacer()
                        Text(freezeDisplayText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.noBuyGreen)
                    }

                    HStack {
                        Image(systemName: "snowflake")
                            .foregroundStyle(.blue)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        Text("Monthly Freeze Allowance")
                        Spacer()
                        Text(store.isPro
                            ? "Unlimited"
                            : "1 / month")
                            .font(.callout)
                            .foregroundStyle(.textSecondary)
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
                                .foregroundStyle(isCompleted ? .mandatoryAmber : .noBuyGreen)
                                .frame(width: 28)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(challengeDuration)-Day Challenge")
                                    .font(.body)
                                if isCompleted {
                                    Text("Completed! 🎉")
                                        .font(.caption)
                                        .foregroundStyle(.mandatoryAmber)
                                } else {
                                    Text("\(remaining) days left")
                                        .font(.caption)
                                        .foregroundStyle(.textSecondary)
                                }
                            }
                            Spacer()
                            Text("\(completed)/\(challengeDuration)")
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundStyle(.noBuyGreen)
                        }
                    }

                    Button {
                        showChallengeSetup = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.noBuyGreen)
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

                // MARK: - Notifications

                Section {
                    Toggle(isOn: $soundEnabled) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundStyle(.noBuyGreen)
                                .frame(width: 28)
                            Text("Sound Effects")
                        }
                    }
                    .tint(.noBuyGreen)
                    .accessibilityLabel("Sound effects")
                    .accessibilityValue(soundEnabled ? "On" : "Off")
                    .accessibilityHint("Double tap to toggle sound effects")

                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.noBuyGreen)
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
                        if store.isPro {
                            exportCSV()
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down.doc")
                                .foregroundStyle(.noBuyGreen)
                                .frame(width: 28)
                                .accessibilityHidden(true)
                            Text(L10n.exportCSV)
                            Spacer()
                            if !store.isPro {
                                Text(L10n.proBadge)
                                    .font(.caption2.bold())
                                    .foregroundStyle(.noBuyGreen)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.noBuyGreenLight))
                            }
                        }
                    }
                    .buttonStyle(.scale)
                    .accessibilityLabel(store.isPro ? "Export data as CSV" : "Export CSV, requires Pro")

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
                    ThemePickerView(showPaywall: $showPaywall)
                } header: {
                    Text("Appearance")
                }

                // MARK: - About

                Section {
                    HStack {
                        Text(L10n.version)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.textSecondary)
                    }

                    HStack {
                        Text(L10n.settingsBuild)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundStyle(.textSecondary)
                    }

                    // User-initiated ask: deep-link straight to the App Store
                    // review form — the native prompt API is rate-limited and
                    // can silently no-op on an explicit tap.
                    Link(destination: URL(string: "https://apps.apple.com/app/id6760716822?action=write-review")!) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
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
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(.noBuyGreen)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            Text(L10n.settingsPrivacy)
                                .font(.body)
                            Text(L10n.settingsPrivacyNote)
                                .font(.caption)
                                .foregroundStyle(.textSecondary)
                        }
                    }
                } header: {
                    Text(L10n.settingsPrivacy)
                }

                // MARK: - Privacy & Legal

                Section {
                    Link(destination: URL(string: "https://theknack2020-sketch.github.io/nobuy/privacy/")!) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundStyle(.noBuyGreen)
                                .frame(width: 28)
                            Text(L10n.privacyPolicy)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.textTertiary)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityLabel("Privacy Policy")
                    .accessibilityHint("Opens privacy policy in browser")

                    Link(destination: URL(string: "https://theknack2020-sketch.github.io/nobuy/terms/")!) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(.noBuyGreen)
                                .frame(width: 28)
                            Text(L10n.termsOfUse)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.textTertiary)
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
                        icon: "💧",
                        name: "AquaFaste",
                        subtitle: "Hydration Tracker",
                        appStoreID: "6760975661"
                    )
                    moreAppRow(
                        icon: "🍽️",
                        name: "Lumifaste",
                        subtitle: "Fasting Tracker",
                        appStoreID: "6760971357"
                    )
                    moreAppRow(
                        icon: "💊",
                        name: "PillPal",
                        subtitle: "Medication Reminder",
                        appStoreID: "6740510337"
                    )
                    moreAppRow(
                        icon: "🐾",
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
                            .foregroundStyle(.textTertiary)
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                            .font(.caption2)
                            .foregroundStyle(.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, DS.Spacing.md)
                    .accessibilityElement(children: .combine)
                }
            }
            .navigationTitle(L10n.settingsTitle)
            .navigationBarTitleDisplayMode(.large)
            .listStyle(.insetGrouped)
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
                Button(L10n.upgradeButton) { showPaywall = true }
                Button(L10n.cancel, role: .cancel) {}
            }
            .alert("Are you sure? All data will be permanently deleted.", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) { resetAllData() }
                Button(L10n.cancel, role: .cancel) {}
            } message: {
                Text("This action cannot be undone. All daily records and streak data will be deleted.")
            }
            .fullScreenCover(isPresented: $showPaywall) { PaywallView(store: store) }
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
            proFeatureRow(icon: "arrow.down.doc.fill", title: L10n.exportCSV)
        } header: { Text(L10n.proFeaturesSection) }
    }

    private func proFeatureRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(.noBuyGreen).frame(width: 28).accessibilityHidden(true)
            Text(title).font(.body)
            Spacer()
            Text(L10n.proFeatureActive).font(.caption).foregroundStyle(.noBuyGreen)
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
    @AppStorage("streakNotificationsEnabled") private var streakNotificationsEnabled = true
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
                            Image(systemName: "bell.slash.fill")
                                .foregroundStyle(.mandatoryAmber)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notifications are off in Settings")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.textPrimary)
                                Text("Open Settings to allow reminders")
                                    .font(.caption)
                                    .foregroundStyle(.textSecondary)
                            }
                        }
                    }
                    .accessibilityLabel("Notifications are off. Open Settings to allow reminders")
                }
            }

            Section {
                Toggle(L10n.dailyReminder, isOn: $dailyReminderEnabled)
                    .tint(.noBuyGreen)
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
                    .tint(.noBuyGreen)
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
                    .tint(.noBuyGreen)
            } footer: {
                Text(L10n.streakNotificationsFooter)
            }

            Section {
                if store.isPro {
                    Toggle(
                        "Weekly Summary",
                        isOn: $weeklySummaryEnabled
                    )
                    .tint(.noBuyGreen)
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
                                .foregroundStyle(.textPrimary)
                            Spacer()
                            Text(L10n.proBadge)
                                .font(.caption2.bold())
                                .foregroundStyle(.noBuyGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.noBuyGreenLight))
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
            PaywallView(store: store)
        }
    }
}

// MARK: - Theme Picker View

struct ThemePickerView: View {
    @Environment(StoreService.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var showPaywall: Bool
    @State private var gridAppeared = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Theme")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.textSecondary)

            LazyVGrid(columns: columns, spacing: DS.Spacing.md) {
                ForEach(AppTheme.allCases) { theme in
                    ThemeDot(
                        theme: theme,
                        isSelected: UserSettings.shared.currentTheme == theme,
                        isLocked: theme.isPro && !store.isPro
                    ) {
                        if theme.isPro, !store.isPro {
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

    private var isRegular: Bool {
        sizeClass == .regular
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: DS.Spacing.sm) {
                ZStack {
                    // Gradient circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.primary, theme.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    // Selection ring
                    if isSelected {
                        Circle()
                            .strokeBorder(Color.textPrimary, lineWidth: 2.5)
                            .frame(width: 52, height: 52)
                    }

                    // Checkmark for selected
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(Font.adaptiveDetail(isRegular: isRegular).weight(.bold))
                            .foregroundStyle(.white)
                            .accessibilityHidden(true)
                    }

                    // Lock + PRO badge for locked themes
                    if isLocked {
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 44, height: 44)

                        Image(systemName: "lock.fill")
                            .font(Font.adaptiveCaption(isRegular: isRegular).weight(.semibold))
                            .foregroundStyle(.white)
                            .accessibilityHidden(true)
                    }
                }

                // Theme name
                Text(theme.displayName)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .textPrimary : .textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                // PRO badge
                if theme.isPro {
                    Text("PRO")
                        .font(Font.adaptiveCaption2(isRegular: isRegular).weight(.bold))
                        .foregroundStyle(.noBuyGreen)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            Capsule().fill(Color.noBuyGreenLight)
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
                Text(icon)
                    .font(.title3)
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
