import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

@MainActor
@Observable
final class AppLockerModel {
    static let shared = AppLockerModel()
    
    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    
    var isAuthorized = false
    var selection = FamilyActivitySelection()
    var isOnboardingComplete: Bool {
        UserDefaults.standard.bool(forKey: "OnboardingComplete")
    }
    
    private init() {
        Task {
            await requestAuthorization()
            loadSelection()
        }
    }
    
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = true
        } catch {
            print("授权失败: \(error)")
            isAuthorized = false
        }
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "OnboardingComplete")
    }
    
    func blockApps() {
        guard isAuthorized else {
            print("未授权，无法锁定应用")
            return
        }
        
        store.shield.applications = selection.applicationTokens
        store.shield.webDomains = selection.webDomainTokens
        
        saveSelection()
        print("已锁定 \(selection.applicationTokens.count) 个应用")
    }
    
    func unblockAllApps() {
        store.shield.applications = nil
        store.shield.webDomains = nil
        
        selection = FamilyActivitySelection()
        UserDefaults.standard.removeObject(forKey: "BlockedAppsSelection")
        
        print("已解锁所有应用")
    }
    
    private func saveSelection() {
        if let data = try? JSONEncoder().encode(selection) {
            UserDefaults.standard.set(data, forKey: "BlockedAppsSelection")
        }
    }
    
    func loadSelection() {
        if let data = UserDefaults.standard.data(forKey: "BlockedAppsSelection"),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = saved
            print("已加载 \(selection.applicationTokens.count) 个已锁定应用")
        }
    }
}
