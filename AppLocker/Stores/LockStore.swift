// LockStore.swift
// 锁定会话数据管理 — CRUD、统计、定时解锁

import Foundation
import SwiftUI
import UserNotifications

@MainActor
class LockStore: ObservableObject {
    static let shared = LockStore()

    @Published var currentSession: LockSession?
    @Published var history: [LockSession] = []
    @Published var isLocking: Bool = false

    private var saveWorkItem: DispatchWorkItem?
    private var timer: Timer?

    private static let storeURL: URL = {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("lock_sessions.json")
    }()

    private init() {
        load()
        // App 回到前台时，检查锁定是否已到期
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkAndCompleteExpiredLock()
        }
        // 启动时检查是否有未结束的过期会话
        checkAndCompleteExpiredLock()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - CRUD

    /// 开始锁定
    func startLock(plannedMinutes: Int, appCount: Int) {
        let session = LockSession(
            startedAt: Date(),
            plannedMinutes: plannedMinutes,
            appCount: appCount
        )
        currentSession = session
        isLocking = true
        startTimer()
        scheduleExpiryNotification(minutes: plannedMinutes)
        BackgroundTaskManager.shared.scheduleExpiryCheck(sessionStart: session.startedAt, plannedMinutes: plannedMinutes)
        save()

        // 通知 ShieldManager 执行屏蔽
        ShieldManager.shared.lockApps()

        NotificationCenter.default.post(
            name: .init("LockStoreDidStartLock"),
            object: session
        )
    }

    /// 提前手动解锁（需要外部验证通过）
    func unlockManually() {
        guard var session = currentSession else { return }
        session.endedAt = Date()
        session.wasEarlyUnlocked = true
        history.append(session)
        currentSession = nil
        isLocking = false
        stopTimer()
        cancelExpiryNotification()
        BackgroundTaskManager.shared.cancelExpiryCheck()

        ShieldManager.shared.unlockAll()
        updateTodayMinutes()
        save()

        NotificationCenter.default.post(
            name: .init("LockStoreDidEndLock"),
            object: session
        )
    }

    /// 到期自动解锁（由 timer 或前台检查触发）
    func completeLock() {
        guard var session = currentSession, session.isExpired else { return }
        session.endedAt = Date()
        session.wasCompleted = true
        history.append(session)
        currentSession = nil
        isLocking = false
        stopTimer()
        cancelExpiryNotification()
        BackgroundTaskManager.shared.cancelExpiryCheck()

        ShieldManager.shared.unlockAll()
        sendUnlockNotification()
        updateTodayMinutes()
        save()

        NotificationCenter.default.post(
            name: .init("LockStoreDidEndLock"),
            object: session
        )
    }

    /// 取消锁定（不记录历史）
    func cancelLock() {
        currentSession = nil
        isLocking = false
        stopTimer()
        cancelExpiryNotification()
        BackgroundTaskManager.shared.cancelExpiryCheck()

        ShieldManager.shared.unlockAll()
        save()

        NotificationCenter.default.post(
            name: .init("LockStoreDidCancelLock"),
            object: nil
        )
    }

    /// 检查并自动完成已过期的锁定（外部调用）
    func checkAndCompleteExpiredLock() {
        guard let session = currentSession, session.isExpired else { return }
        completeLock()
    }

    /// 后台版本（从 BGTaskScheduler 调用）
    func checkAndCompleteExpiredLockInBackground() {
        guard var session = currentSession, session.isExpired else { return }

        session.endedAt = Date()
        session.wasCompleted = true
        history.append(session)
        currentSession = nil
        isLocking = false
        stopTimer()
        cancelExpiryNotification()

        ShieldManager.shared.unlockAll()
        updateTodayMinutes()

        // Save synchronously for background context
        save()

        NotificationCenter.default.post(
            name: .init("LockStoreDidEndLock"),
            object: session
        )
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkLockStatus()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// 每秒检查锁定状态，到期自动解锁
    private func checkLockStatus() {
        guard let session = currentSession else {
            stopTimer()
            return
        }
        if session.isExpired {
            completeLock()
        }
        // 触发 UI 刷新（@Published currentSession 变化）
        objectWillChange.send()
    }

    // MARK: - 本地通知

    /// 调度到期提醒通知
    private func scheduleExpiryNotification(minutes: Int) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notif_lock_expired_title", comment: "")
        content.body = String(format: NSLocalizedString("notif_lock_expired_body", comment: ""), minutes)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(identifier: "lock-expiry", content: content, trigger: trigger)
        center.add(request)
    }

    /// 取消到期提醒通知
    private func cancelExpiryNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["lock-expiry"])
    }

    /// 发送解锁通知（到期时）
    private func sendUnlockNotification() {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("notif_unlock_title", comment: "")
        content.body = NSLocalizedString("notif_unlock_body", comment: "")
        content.sound = .default

        let request = UNNotificationRequest(identifier: "lock-unlock", content: content, trigger: nil)
        center.add(request)
    }

    // MARK: - Widget 支持

    private func updateTodayMinutes() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let todayMinutes = history.filter { session in
            session.startedAt >= today && session.startedAt < tomorrow && session.isCompleted
        }.reduce(0) { $0 + $1.actualMinutes }

        UserDefaults.standard.set(todayMinutes, forKey: "todayLockMinutes")
        UserDefaults.standard.set(isLocking, forKey: "isLocking")
    }

    // MARK: - 统计查询

    var todaySessions: [LockSession] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        return history.filter { session in
            session.startedAt >= today && session.startedAt < tomorrow && session.isCompleted
        }
    }

    var todayTotalMinutes: Int {
        todaySessions.reduce(0) { $0 + $1.actualMinutes }
    }

    var weekSessions: [LockSession] {
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return []
        }
        return history.filter { $0.startedAt >= weekStart && $0.isCompleted }
    }

    var weekTotalMinutes: Int {
        weekSessions.reduce(0) { $0 + $1.actualMinutes }
    }

    var allTimeTotalMinutes: Int {
        history.filter { $0.isCompleted }.reduce(0) { $0 + $1.actualMinutes }
    }

    var allTimeTotalSessions: Int {
        history.filter { $0.isCompleted }.count
    }

    // MARK: - 连胜计算

    /// 当前连续锁定天数（今天或昨天有记录则延续）
    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let sessionDays = Set(history.filter { $0.isCompleted }.map {
            calendar.startOfDay(for: $0.startedAt)
        }).sorted(by: >)

        guard let mostRecent = sessionDays.first else { return 0 }

        let daysFromToday = calendar.dateComponents([.day], from: mostRecent, to: today).day ?? 0
        guard daysFromToday <= 1 else { return 0 }

        var streak = 1
        var checkDate = calendar.date(byAdding: .day, value: -1, to: mostRecent)!

        for day in sessionDays.dropFirst() {
            let daysBetween = calendar.dateComponents([.day], from: day, to: checkDate).day ?? 0
            if daysBetween == 0 {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if daysBetween > 0 {
                break
            }
        }

        return streak
    }

    /// 历史最长连续锁定天数
    var longestStreak: Int {
        let calendar = Calendar.current
        let sessionDays = Set(history.filter { $0.isCompleted }.map {
            calendar.startOfDay(for: $0.startedAt)
        }).sorted()

        guard !sessionDays.isEmpty else { return 0 }

        var longest = 1
        var current = 1

        for i in 1..<sessionDays.count {
            let prev = sessionDays[i - 1]
            let curr = sessionDays[i]
            let gap = calendar.dateComponents([.day], from: prev, to: curr).day ?? 0

            if gap == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }

        return longest
    }

    // MARK: - 持久化

    func save() {
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.performSave()
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    private func performSave() {
        do {
            // 同时保存 history 和当前 session，防止 App 被杀后 currentSession 丢失
            let saveData = LockStoreSaveData(
                history: history,
                currentSession: currentSession
            )
            let data = try JSONEncoder().encode(saveData)
            try data.write(to: Self.storeURL)
        } catch {
            print("[LockStore] Save error: \(error)")
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: Self.storeURL)
            let saveData = try JSONDecoder().decode(LockStoreSaveData.self, from: data)
            history = saveData.history
            currentSession = saveData.currentSession
            // 如果恢复了进行中的 session，检查是否已过期
            if let session = currentSession, session.isExpired {
                // 已过期：直接完成，不进入锁定状态
                completeLock()
            } else if currentSession != nil {
                // 未过期：恢复锁定状态
                isLocking = true
                startTimer()
            }
        } catch {
            history = []
            currentSession = nil
            isLocking = false
        }
    }
}

// MARK: - 持久化数据结构

private struct LockStoreSaveData: Codable {
    let history: [LockSession]
    let currentSession: LockSession?
}
