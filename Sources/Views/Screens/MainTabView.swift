import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeScreen()
                .tabItem {
                    Label("Bugün", systemImage: "circle.fill")
                }
                .tag(0)

            CalendarScreen()
                .tabItem {
                    Label("Takvim", systemImage: "calendar")
                }
                .tag(1)

            SettingsScreen()
                .tabItem {
                    Label("Ayarlar", systemImage: "gearshape")
                }
                .tag(2)
        }
        .tint(.noBuyGreen)
    }
}

#Preview {
    MainTabView()
        .environment(StoreService.shared)
        .modelContainer(for: [DayRecord.self, MandatoryCategory.self], inMemory: true)
}
