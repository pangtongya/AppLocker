import SwiftUI

struct ContentView: View {
    @Environment(AppLockerModel.self) var model
    @State private var selectedTab: Tab = .home
    
    enum Tab: String, CaseIterable {
        case home = "home"
        case settings = "settings"
        
        var title: LocalizedStringKey {
            switch self {
            case .home: return "tab_home"
            case .settings: return "tab_settings"
            }
        }
        
        var icon: String {
            switch self {
            case .home: return "lock.shield"
            case .settings: return "gearshape"
            }
        }
        
        var filledIcon: String {
            switch self {
            case .home: return "lock.shield.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(Tab.home)
                .tabItem {
                    Label(Tab.home.title, systemImage: selectedTab == .home ? Tab.home.filledIcon : Tab.home.icon)
                }
            
            SettingsView()
                .tag(Tab.settings)
                .tabItem {
                    Label(Tab.settings.title, systemImage: selectedTab == .settings ? Tab.settings.filledIcon : Tab.settings.icon)
                }
        }
        .tint(.lockerBlue)
    }
}
