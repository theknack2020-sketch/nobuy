import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var sidebarSelection: Int? = 0
    @Environment(\.horizontalSizeClass) private var sizeClass
    var quickActionHandler: QuickActionHandler?

    var body: some View {
        if sizeClass == .regular {
            NavigationSplitView {
                List(selection: $sidebarSelection) {
                    Label(L10n.tabToday, systemImage: "checkmark.circle.fill").tag(0)
                    Label(L10n.tabCalendar, systemImage: "calendar").tag(1)
                    Label(L10n.tabStats, systemImage: "chart.bar.fill").tag(2)
                    Label(L10n.tabSettings, systemImage: "gearshape.fill").tag(3)
                }
                .navigationTitle(L10n.appTitle)
            } detail: {
                switch sidebarSelection ?? 0 {
                case 0: HomeScreen()
                case 1: CalendarScreen()
                case 2: StatsScreen()
                case 3: SettingsScreen()
                default: HomeScreen()
                }
            }
            .tint(Color.themePrimary)
            .onChange(of: quickActionHandler?.selectedTab) { _, newTab in
                if let newTab {
                    sidebarSelection = newTab
                    quickActionHandler?.selectedTab = nil
                }
            }
        } else {
            TabView(selection: $selectedTab) {
                HomeScreen()
                    .tabItem {
                        Label(L10n.tabToday, systemImage: "checkmark.circle.fill")
                    }
                    .tag(0)

                CalendarScreen()
                    .tabItem {
                        Label(L10n.tabCalendar, systemImage: "calendar")
                    }
                    .tag(1)

                StatsScreen()
                    .tabItem {
                        Label(L10n.tabStats, systemImage: "chart.bar.fill")
                    }
                    .tag(2)

                SettingsScreen()
                    .tabItem {
                        Label(L10n.tabSettings, systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            .tint(Color.themePrimary)
            .onChange(of: selectedTab) { _, _ in
                HapticManager.impact(.light)
            }
            .onChange(of: quickActionHandler?.selectedTab) { _, newTab in
                if let newTab {
                    selectedTab = newTab
                    quickActionHandler?.selectedTab = nil
                }
            }
        }
    }
}

#Preview {
    MainTabView(quickActionHandler: nil)
        .environment(StoreService.shared)
        .modelContainer(for: [DayRecord.self, MandatoryCategory.self], inMemory: true)
}
