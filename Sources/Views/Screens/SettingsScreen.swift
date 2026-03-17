import SwiftUI
import SwiftData
import StoreKit

struct SettingsScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var mandatoryCategories: [MandatoryCategory]
    @State private var showAddCategory = false
    @State private var newCategoryName = ""
    @AppStorage("hasSeededDefaults") private var hasSeededDefaults = false

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
                            Text("Kategori Ekle")
                        }
                    }
                } header: {
                    Text("Zorunlu Harcamalar")
                } footer: {
                    Text("Bu kategorilerdeki harcamalar streak'ini bozmaz.")
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
                            Text("Bildirimler")
                        }
                    }
                } header: {
                    Text("Hatırlatmalar")
                }

                // MARK: - Data
                Section {
                    Button(role: .destructive) {
                        resetAllData()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .frame(width: 28)
                            Text("Tüm Verileri Sil")
                        }
                    }
                } header: {
                    Text("Veri")
                }

                // MARK: - About
                Section {
                    HStack {
                        Text("Versiyon")
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
                            Text("Uygulamayı Değerlendir")
                        }
                    }
                } header: {
                    Text("Hakkında")
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.large)
            .alert("Yeni Kategori", isPresented: $showAddCategory) {
                TextField("Kategori adı", text: $newCategoryName)
                Button("Ekle") {
                    guard !newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let category = MandatoryCategory(name: newCategoryName)
                    modelContext.insert(category)
                    newCategoryName = ""
                }
                Button("İptal", role: .cancel) {
                    newCategoryName = ""
                }
            }
            .onAppear {
                seedDefaultsIfNeeded()
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

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

struct NotificationSettingsView: View {
    @State private var notificationManager = NotificationManager()

    var body: some View {
        List {
            Section {
                Toggle("Günlük Hatırlatma", isOn: .constant(true))
                    .tint(.noBuyGreen)

                HStack {
                    Text("Saat")
                    Spacer()
                    Text("21:00")
                        .foregroundStyle(.textSecondary)
                }
            } footer: {
                Text("Her akşam günü kaydetmeni hatırlatır.")
            }

            Section {
                Toggle("Streak Bildirimleri", isOn: .constant(true))
                    .tint(.noBuyGreen)
            } footer: {
                Text("Yeni streak rekorlarında bildirim alırsın.")
            }
        }
        .navigationTitle("Bildirimler")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsScreen()
        .modelContainer(for: [DayRecord.self, MandatoryCategory.self], inMemory: true)
}
