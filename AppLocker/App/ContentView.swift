import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var lockStore: LockStore
    @EnvironmentObject var shieldManager: ShieldManager
    @EnvironmentObject var authManager: AuthManager

    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "home"
        case stats = "stats"
        case settings = "settings"

            var title: String {
            switch self {
            case .home: return NSLocalizedString("tab_home", comment: "")
            case .stats: return NSLocalizedString("tab_stats", comment: "")
            case .settings: return NSLocalizedString("tab_settings", comment: "")
            }
        }

        var icon: String {
            switch self {
            case .home: return "lock.shield"
            case .stats: return "chart.bar"
            case .settings: return "gearshape"
            }
        }

        var filledIcon: String {
            switch self {
            case .home: return "lock.shield.fill"
            case .stats: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        // 锁定模式：全屏显示 HomeView，隐藏 Tab Bar
        ZStack {
            if lockStore.isLocking {
                HomeView()
                    .environmentObject(appState)
                    .environmentObject(lockStore)
                    .environmentObject(shieldManager)
                    .environmentObject(authManager)
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tag(Tab.home)
                        .environmentObject(appState)
                        .environmentObject(lockStore)
                        .environmentObject(shieldManager)
                        .environmentObject(authManager)
                        .tabItem {
                            Label(Tab.home.title, systemImage: selectedTab == .home ? Tab.home.filledIcon : Tab.home.icon)
                        }

                    StatsView()
                        .tag(Tab.stats)
                        .environmentObject(appState)
                        .environmentObject(lockStore)
                        .tabItem {
                            Label(Tab.stats.title, systemImage: selectedTab == .stats ? Tab.stats.filledIcon : Tab.stats.icon)
                        }

                    SettingsView()
                        .tag(Tab.settings)
                        .environmentObject(appState)
                        .environmentObject(lockStore)
                        .environmentObject(authManager)
                        .tabItem {
                            Label(Tab.settings.title, systemImage: selectedTab == .settings ? Tab.settings.filledIcon : Tab.settings.icon)
                        }
                }
                .tint(.lockerBlue)
                .transition(.opacity)
                .zIndex(0)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: lockStore.isLocking)
    }
}
