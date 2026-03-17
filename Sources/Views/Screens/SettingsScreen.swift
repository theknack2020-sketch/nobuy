import SwiftUI
import SwiftData
import StoreKit

struct SettingsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreService.self) private var store
    @Query private var mandatoryCategories: [MandatoryCategory]
    @State private var showAddCategory = false
    @State private var showDeleteConfirmation = false
    @State private var showPaywall = false
    @State private var showCategoryLimit = false
    @State private var newCategoryName = ""
    @AppStorage("hasSeededDefaults") private var hasSeededDefaults = false
    @AppStorage("launchCount") private var launchCount = 0

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Pro Upgrade
                if !store.isPro {
                    Section {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.noBuyGreen.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "crown.fill")
                                        .foregroundStyle(.noBuyGreen)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(L10n.upgradeButton)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.textPrimary)
                                    Text(L10n.paywallSubtitle)
                                        .font(.caption)
                                        .foregroundStyle(.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.textTertiary)
                            }
                        }
                    }
                }

                // MARK: - Mandatory Categories
                Section {
                    ForEach(mandatoryCategories) { category in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundStyle(.mandatoryAmber)
                                .frame(width: 28)
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
                } header: {
                    Text(L10n.mandatoryCategories)
                } footer: {
                    Text(L10n.mandatoryCategoriesFooter)
                }

                // MARK: - Notifications
                Section {
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
                } header: {
                    Text(L10n.reminders)
                }

                // MARK: - Data
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .frame(width: 28)
                            Text(L10n.deleteAllData)
                        }
                    }
                } header: {
                    Text(L10n.data)
                }

                // MARK: - About
                Section {
                    HStack {
                        Text(L10n.version)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.textSecondary)
                    }

                    Button {
                        requestReview()
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .frame(width: 28)
                            Text(L10n.rateApp)
                        }
                    }
                } header: {
                    Text(L10n.about)
                }
            }
            .navigationTitle(L10n.settingsTitle)
            .navigationBarTitleDisplayMode(.large)
            .alert(L10n.newCategory, isPresented: $showAddCategory) {
                TextField(L10n.categoryName, text: $newCategoryName)
                Button(L10n.add) {
                    guard !newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let category = MandatoryCategory(name: newCategoryName)
                    modelContext.insert(category)
                    newCategoryName = ""
                }
                Button(L10n.cancel, role: .cancel) {
                    newCategoryName = ""
                }
            }
            .alert(L10n.categoryLimitReached, isPresented: $showCategoryLimit) {
                Button(L10n.upgradeButton) {
                    showPaywall = true
                }
                Button(L10n.cancel, role: .cancel) {}
            }
            .alert("Tüm verileri silmek istediğinden emin misin?", isPresented: $showDeleteConfirmation) {
                Button("Sil", role: .destructive) {
                    resetAllData()
                }
                Button(L10n.cancel, role: .cancel) {}
            } message: {
                Text("Bu işlem geri alınamaz. Tüm günlük kayıtlar ve streak bilgilerin silinecek.")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(store: store)
            }
            .onAppear {
                seedDefaultsIfNeeded()
                trackLaunch()
            }
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
        } catch {
            print("Failed to reset data: \(error)")
        }
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

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

struct NotificationSettingsView: View {
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = true
    @AppStorage("streakNotificationsEnabled") private var streakNotificationsEnabled = true

    var body: some View {
        List {
            Section {
                Toggle(L10n.dailyReminder, isOn: $dailyReminderEnabled)
                    .tint(.noBuyGreen)
                    .onChange(of: dailyReminderEnabled) { _, enabled in
                        if enabled {
                            Task {
                                let manager = NotificationManager()
                                await manager.requestAuthorization()
                            }
                        }
                    }

                HStack {
                    Text(L10n.time)
                    Spacer()
                    Text("21:00")
                        .foregroundStyle(.textSecondary)
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
        }
        .navigationTitle(L10n.notifications)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsScreen()
        .environment(StoreService.shared)
        .modelContainer(for: [DayRecord.self, MandatoryCategory.self], inMemory: true)
}
