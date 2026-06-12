// LockSession.swift
// 锁定会话数据模型

import Foundation

struct LockSession: Identifiable, Codable, Equatable {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var plannedMinutes: Int          // 计划锁定分钟数
    var appCount: Int                // 被锁应用数量
    var wasCompleted: Bool = false   // 是否正常到期解锁
    var wasEarlyUnlocked: Bool = false // 是否提前强制解锁

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        plannedMinutes: Int = 25,
        appCount: Int = 0
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.plannedMinutes = plannedMinutes
        self.appCount = appCount
    }

    /// 是否已结束
    var isCompleted: Bool {
        endedAt != nil
    }

    /// 实际锁定分钟数
    var actualMinutes: Int {
        guard let end = endedAt else {
            return Int(Date().timeIntervalSince(startedAt) / 60)
        }
        return Int(end.timeIntervalSince(startedAt) / 60)
    }

    /// 实际锁定秒数
    var actualSeconds: Int {
        guard let end = endedAt else {
            return Int(Date().timeIntervalSince(startedAt))
        }
        return Int(end.timeIntervalSince(startedAt))
    }

    /// 剩余秒数（锁定中时计算）
    var remainingSeconds: Int {
        let total = plannedMinutes * 60
        let elapsed = Int(Date().timeIntervalSince(startedAt))
        return max(0, total - elapsed)
    }

    /// 是否已到期
    var isExpired: Bool {
        remainingSeconds <= 0
    }

    /// 格式化的剩余时间 "25:30"
    var formattedRemaining: String {
        let secs = remainingSeconds
        let minutes = secs / 60
        let seconds = secs % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// 格式化的实际锁定时间
    var formattedDuration: String {
        let totalSeconds = actualSeconds
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// 完成率 (0.0 - 1.0)
    var completionRate: Double {
        guard plannedMinutes > 0 else { return 0 }
        return min(Double(actualMinutes) / Double(plannedMinutes), 1.0)
    }
}
