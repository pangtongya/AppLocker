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
        } catch {
            print("Failed to request authorization: \(error)")
            isAuthorized = false
        }
    }
    
    func blockSelectedApps() {
        guard isAuthorized else { return }
        
        // 使用ManagedSettings的shield来锁定选择的应用
        store.shield.applications = selection.applicationTokens
        // store.shield.applicationCategories = selection.categoryTokens
        store.shield.webDomains = selection.webDomainTokens
    }
    
    func unblockAllApps() {
        store.shield.applications = nil
        // store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
}
