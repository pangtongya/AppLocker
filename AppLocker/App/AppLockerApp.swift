import SwiftUI

@main
struct AppLockerApp: App {
    @StateObject private var appState: AppState
    @StateObject private var lockStore: LockStore
    @StateObject private var shieldManager: ShieldManager
    @StateObject private var authManager: AuthManager

    init() {
        _appState = StateObject(wrappedValue: AppState.shared)
        _lockStore = StateObject(wrappedValue: LockStore.shared)
        _shieldManager = StateObject(wrappedValue: ShieldManager.shared)
        _authManager = StateObject(wrappedValue: AuthManager.shared)
    }

    var body: some Scene {
        WindowGroup {
            if appState.hasCompletedOnboarding {
                ContentView()
                    .environmentObject(appState)
                    .environmentObject(lockStore)
                    .environmentObject(shieldManager)
                    .environmentObject(authManager)
            } else {
                GuideView()
                    .environmentObject(appState)
                    .environmentObject(shieldManager)
            }
        }
    }
}
