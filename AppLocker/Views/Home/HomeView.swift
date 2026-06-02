import SwiftUI
import FamilyControls

struct HomeView: View {
    @Environment(AppLockerModel.self) var model
    @State private var isPickerPresented = false
    @State private var showUnlockConfirm = false
    @State private var hasLocked = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // 顶部大图标
                        topSection

                        // 状态文字
                        statusSection

                        // 主操作区
                        if hasLocked {
                            lockedSection
                        } else {
                            unlockedSection
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("应用锁")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $isPickerPresented) {
                NavigationStack {
                    FamilyActivityPicker(selection: Binding(
                        get: { model.selection },
                        set: { model.selection = $0 }
                    ))
                    .navigationTitle("选择应用")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("完成") { isPickerPresented = false }
                        }
                    }
                }
                .presentationDetents([.large])
            }
            .alert("解锁确认", isPresented: $showUnlockConfirm) {
                Button("取消", role: .cancel) { }
                Button("解锁", role: .destructive) {
                    model.unblockAllApps()
                    hasLocked = false
                }
            } message: {
                Text("解锁后，这些应用将可以正常打开。确定要继续吗？")
            }
            .onAppear {
                // 启动时检查是否已有锁定
                if !model.selection.applicationTokens.isEmpty {
                    hasLocked = true
                }
            }
        }
    }

    // MARK: - 顶部图标区
    private var topSection: some View {
        ZStack {
            // 背景光晕
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (hasLocked ? Color.lockerGreen : Color.lockerBlue).opacity(0.18),
                            .clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)
                .blur(radius: 18)

            // 主图标
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: hasLocked
                                ? [Color.lockerGreen, Color.lockerGreen.opacity(0.75)]
                                : [Color.lockerBlue, Color.lockerBlue.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .shadow(
                        color: (hasLocked ? Color.lockerGreen : Color.lockerBlue).opacity(0.35),
                        radius: 14, x: 0, y: 7
                    )

                Image(systemName: hasLocked ? "lock.fill" : "lock")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(height: 180)
    }

    // MARK: - 状态文字
    private var statusSection: some View {
        VStack(spacing: 6) {
            Text(hasLocked ? "应用已锁定" : "保护您的隐私")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.primary)

            Text(hasLocked
                  ? "\(model.selection.applicationTokens.count) 个应用已受保护"
                  : "选择应用，一键锁定")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - 未锁定状态操作区
    private var unlockedSection: some View {
        VStack(spacing: 14) {
            // 选择应用按钮（始终显示）
            Button { isPickerPresented = true } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.lockerBlue)
                            .frame(width: 36, height: 36)
                        Image(systemName: "app.badge.checkmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("选择应用")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("从系统列表中选择要锁定的应用")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(ScaleButtonStyle())
            .sensoryFeedback(.selection, trigger: isPickerPresented)

            // 已选择应用 → 显示锁定按钮
            if !model.selection.applicationTokens.isEmpty {
                Button {
                    model.blockApps()
                    hasLocked = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text("锁定 \(model.selection.applicationTokens.count) 个应用")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(
                            colors: [Color.lockerBlue, Color.lockerBlue.opacity(0.85)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.lockerBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .sensoryFeedback(.success, trigger: hasLocked)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: model.selection.applicationTokens.count)
    }

    // MARK: - 已锁定状态操作区
    private var lockedSection: some View {
        VStack(spacing: 14) {
            // 已锁定卡片
            GlassCard {
                VStack(spacing: 14) {
                    HStack {
                        Text("已锁定")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(model.selection.applicationTokens.count) 个应用")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.lockerGreen)
                    }

                    Divider()

                    Button { isPickerPresented = true } label: {
                        HStack {
                            Label("更换应用", systemImage: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }

            // 解锁按钮
            Button { showUnlockConfirm = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lock.open")
                        .font(.system(size: 15, weight: .semibold))
                    Text("解锁所有应用")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [Color.lockerOrange, Color.lockerOrange.opacity(0.85)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.lockerOrange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
            .sensoryFeedback(.warning, trigger: showUnlockConfirm)
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    HomeView()
}
