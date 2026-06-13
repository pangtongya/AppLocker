import SwiftUI

@main
struct AppLockerApp: App {
    @StateObject private var appState: AppState
    @StateObject private var lockStore: LockStore
    @StateObject private var shieldManager: ShieldManager
    @StateObject private var authManager: AuthManager
    @StateObject private var presetStore: PresetStore

    init() {
        _appState = StateObject(wrappedValue: AppState.shared)
        _lockStore = StateObject(wrappedValue: LockStore.shared)
        _shieldManager = StateObject(wrappedValue: ShieldManager.shared)
        _authManager = StateObject(wrappedValue: AuthManager.shared)
        _presetStore = StateObject(wrappedValue: PresetStore.shared)
    }

    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environmentObject(appState)
                .environmentObject(lockStore)
                .environmentObject(shieldManager)
                .environmentObject(authManager)
                .environmentObject(presetStore)
        }
    }
}

/// 主视图包装器 - 用于注册后台任务
private struct MainAppView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var lockStore: LockStore
    @EnvironmentObject var shieldManager: ShieldManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var presetStore: PresetStore

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                ContentView()
            } else {
                GuideView()
            }
        }
        .onAppear {
            // 注册后台任务（仅正式运行时，避免测试崩溃）
            if NSClassFromString("XCTest") == nil {
                BackgroundTaskManager.shared.registerTask()
            }
        }
    }
}
