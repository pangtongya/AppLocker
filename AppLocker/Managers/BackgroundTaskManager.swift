import Foundation
import BackgroundTasks

/// 后台任务管理器：确保锁定在 App 后台时仍然可以自动解锁
@MainActor
class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    static let taskIdentifier = "com.pangtong.applocker.lockexpiry"

    private var isRegistered = false
    private var currentSessionStart: Date?
    private var currentPlannedMinutes: Int?

    private init() {}

    // MARK: - Registration

    /// 注册后台任务（在 App 启动时调用）
    func registerTask() {
        guard !isRegistered, !isRunningTests() else { return }
        isRegistered = true
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { [weak self] task in
            self?.handleTaskExpiry(task as! BGProcessingTask)
        }
    }

    // MARK: - Schedule

    /// 调度后台任务（开始锁定时调用）
    func scheduleExpiryCheck(sessionStart: Date, plannedMinutes: Int) {
        guard isRegistered, !isRunningTests() else { return }
        currentSessionStart = sessionStart
        currentPlannedMinutes = plannedMinutes

        let request = BGProcessingTaskRequest(identifier: Self.taskIdentifier)
        // 在预计解锁时间前 10 秒调度
        let scheduledDate = sessionStart.addingTimeInterval(TimeInterval(plannedMinutes * 60 - 10))
        request.earliestBeginDate = scheduledDate
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
            print("[BGTaskManager] Scheduled expiry check for \(scheduledDate)")
        } catch {
            print("[BGTaskManager] Failed to schedule: \(error)")
        }
    }

    /// 取消后台任务
    func cancelExpiryCheck() {
        guard isRegistered, !isRunningTests() else { return }
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)
        currentSessionStart = nil
        currentPlannedMinutes = nil
        print("[BGTaskManager] Cancelled expiry check")
    }

    // MARK: - Handle

    /// 处理后台任务到期
    private func handleTaskExpiry(_ task: BGProcessingTask) {
        print("[BGTaskManager] Handling expiry check")

        task.expirationHandler = {
            print("[BGTaskManager] Task expired before completion")
        }

        Task { @MainActor in
            LockStore.shared.checkAndCompleteExpiredLockInBackground()
            task.setTaskCompleted(success: true)
        }
    }

    // MARK: - Helpers

    private func isRunningTests() -> Bool {
        NSClassFromString("XCTest") != nil
    }
}
