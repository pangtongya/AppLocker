import Foundation
import SwiftUI

/// 专注预设管理
@MainActor
class PresetStore: ObservableObject {
    static let shared = PresetStore()

    @Published var presets: [FocusPreset] = []
    @Published var activePresetId: UUID?
    @Published var isCustomPresetActive: Bool = false

    private let saveKey = "FocusPresets"
    private var saveWorkItem: DispatchWorkItem?

    var activePreset: FocusPreset? {
        guard !isCustomPresetActive else { return nil }
        return presets.first { $0.id == activePresetId }
    }

    private init() {
        load()
    }

    // MARK: - CRUD

    func addPreset(_ preset: FocusPreset) {
        presets.append(preset)
        save()
    }

    func updatePreset(_ preset: FocusPreset) {
        guard let index = presets.firstIndex(where: { $0.id == preset.id }) else { return }
        presets[index] = preset
        save()
    }

    func removePreset(_ id: UUID) {
        presets.removeAll { $0.id == id }
        if activePresetId == id {
            activePresetId = presets.first?.id
        }
        save()
    }

    func selectPreset(_ id: UUID) {
        activePresetId = id
        isCustomPresetActive = false
        save()
    }

    func selectCustom() {
        isCustomPresetActive = true
        activePresetId = nil
    }

    func resetToDefaults() {
        presets = FocusPreset.defaults
        activePresetId = presets.first?.id
        isCustomPresetActive = false
        save()
    }

    // MARK: - Persistence

    func save() {
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.performSave()
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    private func performSave() {
        do {
            let data = try JSONEncoder().encode(PresetStoreData(
                presets: presets,
                activePresetId: activePresetId,
                isCustomPresetActive: isCustomPresetActive
            ))
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("[PresetStore] Save error: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            resetToDefaults()
            return
        }
        do {
            let decoded = try JSONDecoder().decode(PresetStoreData.self, from: data)
            presets = decoded.presets
            activePresetId = decoded.activePresetId
            isCustomPresetActive = decoded.isCustomPresetActive
        } catch {
            resetToDefaults()
        }
    }
}

// MARK: - Codable Helpers

private struct PresetStoreData: Codable {
    let presets: [FocusPreset]
    let activePresetId: UUID?
    let isCustomPresetActive: Bool
}
