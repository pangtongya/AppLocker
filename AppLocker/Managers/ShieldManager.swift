// ShieldManager.swift
// FamilyControls 屏蔽管理 — 只负责授权和屏蔽/解封操作

import Foundation
import FamilyControls
import ManagedSettings
import SwiftUI

@MainActor
class ShieldManager: ObservableObject {
    static let shared = ShieldManager()

    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var selection = FamilyActivitySelection()
    @Published var lockedAppCount: Int = 0
    @Published var needsSettingsAuthorization: Bool = false

    private let store = ManagedSettingsStore()
    private let selectionKey = "BlockedAppsSelection"

    private init() {
        // 暂时不加载选择（FamilyActivitySelection 无法编码持久化）
        // loadSelection()
        Task {
            await refreshAuthorization()
        }
        // 监听应用回到前台，刷新授权状态
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.refreshAuthorization()
            }
        }
    }

    // MARK: - 授权

    enum AuthorizationStatus: String {
        case notDetermined = "未确定"
        case approved = "已授权"
        case denied = "已拒绝"
    }

    /// 检查当前授权状态（不弹窗）
    func refreshAuthorization() async {
        let status = AuthorizationCenter.shared.authorizationStatus
        switch status {
        case .notDetermined:
            authorizationStatus = .notDetermined
            isAuthorized = false
            needsSettingsAuthorization = false
        case .approved, .approvedWithDataAccess:
            authorizationStatus = .approved
            isAuthorized = true
            needsSettingsAuthorization = false
        case .denied:
            authorizationStatus = .denied
            isAuthorized = false
            needsSettingsAuthorization = true
        @unknown default:
            authorizationStatus = .notDetermined
            isAuthorized = false
            needsSettingsAuthorization = false
        }
    }
    
    /// 打开系统设置页（引导用户去重新授权）
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    /// 请求屏幕使用时间授权（会弹系统窗口）
    func requestAuthorization() async -> Bool {
        await refreshAuthorization()
        guard authorizationStatus != .approved else {
            return true
        }

        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = true
            authorizationStatus = .approved
            needsSettingsAuthorization = false
            return true
        } catch {
            print("[ShieldManager] Authorization failed: \(error)")
            await refreshAuthorization()
            // 授权失败后，检查是否需要引导用户去设置页
            if authorizationStatus == .denied {
                needsSettingsAuthorization = true
            }
            return false
        }
    }

    /// 刷新授权状态
    func refreshAuthorizationStatus() async {
        await refreshAuthorization()
    }

    // MARK: - 屏蔽操作

    /// 锁定应用（设置屏蔽）
    func lockApps() {
        guard isAuthorized else {
            print("[ShieldManager] Not authorized to lock apps")
            return
        }
        // 屏蔽应用和网站（类别屏蔽需要单独处理）
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        
        // 更新计数（包括应用+类别+网站）
        lockedAppCount = selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
        
        print("[ShieldManager] Locked \(lockedAppCount) items (apps: \(selection.applicationTokens.count), categories: \(selection.categoryTokens.count))")
    }

    /// 解锁所有应用
    func unlockAll() {
        store.shield.applications = nil
        store.shield.webDomains = nil
        lockedAppCount = 0
        print("[ShieldManager] Unlocked all apps")
    }

    // MARK: - 选择管理（暂时不持久化，FamilyActivitySelection 无法编码）

    /// 清除已保存的选择
    func clearSelection() {
        selection = FamilyActivitySelection()
        lockedAppCount = 0
    }
}
