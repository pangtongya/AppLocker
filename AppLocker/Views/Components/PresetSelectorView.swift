import SwiftUI

/// 专注预设选择器（水平滚动条）
struct PresetSelectorView: View {
    @EnvironmentObject var presetStore: PresetStore
    let onSelectPreset: (FocusPreset) -> Void

    @State private var showManager = false

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(LocalizedStringKey("preset_title"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { showManager = true }) {
                    Text(LocalizedStringKey("preset_manage"))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.lockerBlue)
                }
            }
            .sheet(isPresented: $showManager) {
                PresetManageView()
                    .environmentObject(presetStore)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // 自定义模式（没有选择预设）
                    presetChip(
                        name: NSLocalizedString("preset_custom", comment: ""),
                        icon: "slider.horizontal.3",
                        color: .gray,
                        isSelected: presetStore.isCustomPresetActive
                    ) {
                        presetStore.selectCustom()
                        onSelectPreset(FocusPreset(name: "Custom", durationMinutes: 25))
                    }

                    ForEach(presetStore.presets) { preset in
                        presetChip(
                            name: preset.name,
                            icon: preset.icon,
                            color: preset.color,
                            isSelected: presetStore.activePresetId == preset.id && !presetStore.isCustomPresetActive
                        ) {
                            presetStore.selectPreset(preset.id)
                            onSelectPreset(preset)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollClipDisabled()
        }
    }

    private func presetChip(name: String, icon: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(name)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                ? color
                : color.opacity(0.1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color.clear : color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    PresetSelectorView(onSelectPreset: { _ in })
        .environmentObject(PresetStore.shared)
        .padding()
}
