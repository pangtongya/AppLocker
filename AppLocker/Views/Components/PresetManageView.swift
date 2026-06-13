import SwiftUI

/// 预设管理界面
struct PresetManageView: View {
    @EnvironmentObject var presetStore: PresetStore
    @Environment(\.dismiss) private var dismiss

    @State private var showAddPreset = false
    @State private var editingPreset: FocusPreset?
    @State private var showDeleteConfirm: UUID?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(presetStore.presets) { preset in
                        HStack(spacing: 12) {
                            Image(systemName: preset.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(preset.color)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.name)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(.primary)
                                Text(String(format: NSLocalizedString("preset_duration_format", comment: ""), preset.durationMinutes))
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if presetStore.activePresetId == preset.id && !presetStore.isCustomPresetActive {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.lockerBlue)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            presetStore.selectPreset(preset.id)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                withAnimation {
                                    presetStore.removePreset(preset.id)
                                }
                            } label: {
                                Label(NSLocalizedString("preset_delete", comment: ""), systemImage: "trash")
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            presetStore.removePreset(presetStore.presets[index].id)
                        }
                    }
                } header: {
                    Text(LocalizedStringKey("preset_list_header"))
                } footer: {
                    Text(LocalizedStringKey("preset_list_footer"))
                }
            }
            .navigationTitle(LocalizedStringKey("preset_manage"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(LocalizedStringKey("reset_action")) {
                        presetStore.resetToDefaults()
                    }
                    .foregroundColor(.lockerOrange)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(LocalizedStringKey("password_close")) { dismiss() }
                }
            }
        }
    }
}

#Preview {
    PresetManageView()
        .environmentObject(PresetStore.shared)
}
