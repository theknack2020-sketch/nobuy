import SwiftUI
import SwiftData
import StoreKit

struct SettingsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var mandatoryCategories: [MandatoryCategory]
    @State private var showAddCategory = false
    @State private var showDeleteConfirmation = false
    @State private var newCategoryName = ""
    @AppStorage("hasSeededDefaults") private var hasSeededDefaults = false
    @AppStorage("launchCount") private var launchCount = 0

    var body: some View {
        NavigationStack {
            List {
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
                        showAddCategory = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.noBuyGreen)
                            Text(L10n.addCategory)
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
            .alert("Tüm verileri silmek istediğinden emin misin?", isPresented: $showDeleteConfirmation) {
                Button("Sil", role: .destructive) {
                    resetAllData()
                }
                Button(L10n.cancel, role: .cancel) {}
            } message: {
                Text("Bu işlem geri alınamaz. Tüm günlük kayıtlar ve streak bilgilerin silinecek.")
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
        .modelContainer(for: [DayRecord.self, MandatoryCategory.self], inMemory: true)
}
