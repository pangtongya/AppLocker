// AppState.swift
// 全局应用状态

import SwiftUI
import Foundation

@MainActor
class AppState: ObservableObject, @preconcurrency Codable {
    static let shared = AppState()

    @Published var hasCompletedOnboarding: Bool = false
    @Published var weeklyGoalMinutes: Int = 150       // 每周目标（分钟），默认150

    private var saveWorkItem: DispatchWorkItem?

    private init() {
        load()
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case hasCompletedOnboarding
        case weeklyGoalMinutes
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        try container.encode(weeklyGoalMinutes, forKey: .weeklyGoalMinutes)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)
        self.weeklyGoalMinutes = try container.decodeIfPresent(Int.self, forKey: .weeklyGoalMinutes) ?? 150
    }

    // MARK: - Persistence

    private static let storeURL: URL = {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("app_state.json")
    }()

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
            let data = try JSONEncoder().encode(self)
            try data.write(to: Self.storeURL)
        } catch {
            print("[AppState] Save error: \(error)")
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: Self.storeURL)
            let decoded = try JSONDecoder().decode(AppState.self, from: data)
            self.hasCompletedOnboarding = decoded.hasCompletedOnboarding
            self.weeklyGoalMinutes = decoded.weeklyGoalMinutes
        } catch {
            self.hasCompletedOnboarding = false
            self.weeklyGoalMinutes = 150
        }
    }
}
