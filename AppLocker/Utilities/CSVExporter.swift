import Foundation

/// CSV 导出工具 - 消除重复代码
struct CSVExporter {
    /// 生成锁定记录的 CSV 字符串
    static func exportSessionsToCSV(sessions: [LockSession]) -> String {
        let header = [
            NSLocalizedString("csv_header_start", comment: ""),
            NSLocalizedString("csv_header_end", comment: ""),
            NSLocalizedString("csv_header_planned", comment: ""),
            NSLocalizedString("csv_header_actual", comment: ""),
            NSLocalizedString("csv_header_appcount", comment: ""),
            NSLocalizedString("csv_header_status", comment: "")
        ].joined(separator: ",")

        var csvString = header + "\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        for session in sessions.sorted(by: { $0.startedAt > $1.startedAt }) {
            let startDate = dateFormatter.string(from: session.startedAt)
            let endDateStr = session.endedAt != nil ? dateFormatter.string(from: session.endedAt!) : ""
            let status: String
            if session.wasCompleted {
                status = NSLocalizedString("csv_status_completed", comment: "")
            } else if session.wasEarlyUnlocked {
                status = NSLocalizedString("csv_status_early_unlock", comment: "")
            } else {
                status = ""
            }

            let row = "\"\(startDate)\",\"\(endDateStr)\",\(session.plannedMinutes),\(session.actualMinutes),\(session.appCount),\"\(status)\"\n"
            csvString += row
        }

        return csvString
    }

    /// 将 CSV 写入临时文件并返回 URL
    static func writeCSVToTempFile(sessions: [LockSession], fileName: String = "AppLocker") -> URL? {
        let csvString = exportSessionsToCSV(sessions: sessions)
        let tempDir = FileManager.default.temporaryDirectory
        let csvFile = tempDir.appendingPathComponent("\(fileName)_\(Int(Date().timeIntervalSince1970)).csv")

        do {
            try csvString.write(to: csvFile, atomically: true, encoding: .utf8)
            return csvFile
        } catch {
            print("[CSVExporter] Failed to write CSV: \(error)")
            return nil
        }
    }
}
