import Foundation
import AppIntents

// MARK: - 开始专注

/// 开始专注的 Siri 快捷指令
struct StartFocusIntent: AppIntent {
    @Parameter(title: "siri_param_duration", default: 25)
    var durationMinutes: Int

    static var parameterSummary: some ParameterSummary {
        Summary("siri_param_summary_start")
    }

    nonisolated static let title: LocalizedStringResource = "siri_intent_start_title"
    nonisolated static let description: LocalizedStringResource = "siri_intent_start_desc"

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 验证时长
        let clampedMinutes = min(max(durationMinutes, 1), 480)
        let appCount = ShieldManager.shared.lockedAppCount

        // 检查是否已授权
        guard ShieldManager.shared.isAuthorized else {
            throw IntentError.notAuthorized
        }

        // 检查是否选择了要锁定的应用
        guard appCount > 0 else {
            throw IntentError.noAppsSelected
        }

        // 开始专注
        LockStore.shared.startLock(plannedMinutes: clampedMinutes, appCount: appCount)

        let dialog = IntentDialog(stringLiteral: String(format: NSLocalizedString("siri_start_focus", comment: ""), clampedMinutes))
        return .result(dialog: dialog)
    }
}

// MARK: - 结束专注

struct EndFocusIntent: AppIntent {
    nonisolated static let title: LocalizedStringResource = "siri_intent_end_title"
    nonisolated static let description: LocalizedStringResource = "siri_intent_end_desc"

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
    nonisolated static let title: LocalizedStringResource = "siri_intent_status_title"
    nonisolated static let description: LocalizedStringResource = "siri_intent_status_desc"

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
    case noAppsSelected

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notAuthorized:
            return "siri_error_not_authorized"
        case .notLocking:
            return "siri_error_not_locking"
        case .noAppsSelected:
            return "siri_error_no_apps"
        }
    }
}
