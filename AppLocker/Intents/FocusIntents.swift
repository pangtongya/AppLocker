import Foundation
import AppIntents

// MARK: - 开始专注

/// 开始专注的 Siri 快捷指令
struct StartFocusIntent: AppIntent {
    @Parameter(title: "Duration (minutes)", default: 25)
    var durationMinutes: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Start a \(\.$durationMinutes) minute focus session")
    }

    nonisolated static let title: LocalizedStringResource = "Start Focus"
    nonisolated static let description: LocalizedStringResource = "Start a focus session with a specified duration"

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 验证时长
        let clampedMinutes = min(max(durationMinutes, 1), 480)
        let appCount = ShieldManager.shared.lockedAppCount

        // 检查是否已授权
        guard ShieldManager.shared.isAuthorized else {
            throw IntentError.notAuthorized
        }

        // 开始专注
        LockStore.shared.startLock(plannedMinutes: clampedMinutes, appCount: max(appCount, 1))

        let dialog = IntentDialog(stringLiteral: String(format: NSLocalizedString("siri_start_focus", comment: ""), clampedMinutes))
        return .result(dialog: dialog)
    }
}

// MARK: - 结束专注

struct EndFocusIntent: AppIntent {
    nonisolated static let title: LocalizedStringResource = "End Focus"
    nonisolated static let description: LocalizedStringResource = "End the current focus session"

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard LockStore.shared.isLocking else {
            throw IntentError.notLocking
        }

        LockStore.shared.unlockManually()

        let dialog = IntentDialog(stringLiteral: NSLocalizedString("siri_end_focus", comment: ""))
        return .result(dialog: dialog)
    }
}

// MARK: - 查询专注状态

struct FocusStatusIntent: AppIntent {
    nonisolated static let title: LocalizedStringResource = "Focus Status"
    nonisolated static let description: LocalizedStringResource = "Check current focus session status"

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        if LockStore.shared.isLocking, let session = LockStore.shared.currentSession {
            let remaining = session.formattedRemaining
            let dialog = IntentDialog(stringLiteral: String(format: NSLocalizedString("siri_status_locking", comment: ""), remaining))
            return .result(dialog: dialog)
        } else {
            let todayMinutes = LockStore.shared.todayTotalMinutes
            let dialog = IntentDialog(stringLiteral: String(format: NSLocalizedString("siri_status_idle", comment: ""), todayMinutes))
            return .result(dialog: dialog)
        }
    }
}

// MARK: - 错误

enum IntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case notAuthorized
    case notLocking

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notAuthorized:
            return "Screen Time permission is required. Please open the app first."
        case .notLocking:
            return "No active focus session."
        }
    }
}
