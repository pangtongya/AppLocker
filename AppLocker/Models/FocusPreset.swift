import Foundation
import SwiftUI

/// 专注预设：保存常用的 App 阻隔方案
struct FocusPreset: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var icon: String           // SF Symbol name
    var durationMinutes: Int   // 默认专注时长
    var colorHex: String       // 预设颜色
    var sortOrder: Int         // 排序顺序

    /// 这些 token 的名称（因 FamilyActivitySelection 不可编码）
    var appTokenNames: [String]
    var categoryTokenNames: [String]
    var webDomainTokenNames: [String]

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "star.fill",
        durationMinutes: Int = 25,
        colorHex: String = "007AFF",
        sortOrder: Int = 0,
        appTokenNames: [String] = [],
        categoryTokenNames: [String] = [],
        webDomainTokenNames: [String] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.durationMinutes = durationMinutes
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.appTokenNames = appTokenNames
        self.categoryTokenNames = categoryTokenNames
        self.webDomainTokenNames = webDomainTokenNames
    }

    var color: Color {
        Color(hex: colorHex)
    }

    static let defaults: [FocusPreset] = [
        FocusPreset(
            name: NSLocalizedString("preset_work", comment: ""),
            icon: "briefcase.fill",
            durationMinutes: 45,
            colorHex: "007AFF",
            sortOrder: 0
        ),
        FocusPreset(
            name: NSLocalizedString("preset_study", comment: ""),
            icon: "book.fill",
            durationMinutes: 25,
            colorHex: "34C759",
            sortOrder: 1
        ),
        FocusPreset(
            name: NSLocalizedString("preset_relax", comment: ""),
            icon: "moon.fill",
            durationMinutes: 60,
            colorHex: "FF9500",
            sortOrder: 2
        )
    ]
}
