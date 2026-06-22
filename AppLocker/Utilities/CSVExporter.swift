import Foundation

/// CSV 导出工具 - 消除重复代码
struct CSVExporter {
    /// 生成锁定记录的 CSV 字符串
    static func exportSessionsToCSV(sessions: [LockSession]) -> String {
        var csvString = "日期,开始时间,结束时间,计划分钟,实际分钟,被锁应用数,是否到期解锁\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        for session in sessions.sorted(by: { $0.startedAt > $1.startedAt }) {
            let startDate = dateFormatter.string(from: session.startedAt)
            let endDateStr = session.endedAt != nil ? dateFormatter.string(from: session.endedAt!) : ""
            let status = session.wasCompleted ? "是" : (session.wasEarlyUnlocked ? "提前解锁" : "")

            let row = "\"\(startDate)\",\"\(endDateStr)\",\(session.plannedMinutes),\(session.actualMinutes),\(session.appCount),\"\(status)\"\n"
            csvString += row
        }

        return csvString
    }

    /// 将 CSV 写入临时文件并返回 URL
    static func writeCSVToTempFile(sessions: [LockSession], fileName: String = "锁定记录") -> URL? {
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
