import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings

@MainActor
@Observable
final class AppBlockerModel {
    static let shared = AppBlockerModel()
    
    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    
    var isAuthorized = false
    var selection = FamilyActivitySelection()
    
    private init() {
        Task {
            await requestAuthorization()
        }
    }
    
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = true
            print("Authorization successful")
        } catch {
            print("Failed to request authorization: \(error)")
            isAuthorized = false
        }
    }
    
    func blockSelectedApps() {
        guard isAuthorized else { 
            print("Not authorized")
            return 
        }
        
        // 使用ManagedSettings的shield来锁定选择的应用
        store.shield.applications = selection.applicationTokens
        store.shield.webDomains = selection.webDomainTokens
        
        // 保存选择到UserDefaults，以便重启后恢复
        saveSelection()
        
        print("Blocked \(selection.applicationTokens.count) apps")
    }
    
    func unblockAllApps() {
        store.shield.applications = nil
        store.shield.webDomains = nil
        
        // 清除保存的选择
        UserDefaults.standard.removeObject(forKey: "BlockedAppsSelection")
        
        print("Unblocked all apps")
    }
    
    private func saveSelection() {
        // 将选择序列化保存
        if let data = try? JSONEncoder().encode(selection) {
            UserDefaults.standard.set(data, forKey: "BlockedAppsSelection")
        }
    }
    
    func loadSelection() {
        // 从UserDefaults加载保存的选择
        if let data = UserDefaults.standard.data(forKey: "BlockedAppsSelection"),
           let savedSelection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = savedSelection
            print("Loaded saved selection with \(selection.applicationTokens.count) apps")
        }
    }
}
