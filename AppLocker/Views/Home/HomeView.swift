import SwiftUI
import FamilyControls

struct HomeView: View {
    @Environment(AppLockerModel.self) var model
    @State private var isPickerPresented = false
    @State private var showUnlockConfirm = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 顶部状态卡片
                        statusCard
                        
                        // 操作按钮区
                        if model.selection.applicationTokens.isEmpty {
                            emptyStateView
                        } else {
                            lockedAppsView
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("应用锁")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $isPickerPresented) {
                FamilyActivityPicker(selection: Binding(
                    get: { model.selection },
                    set: { model.selection = $0 }
                ))
                .presentationDetents([.large])
            }
            .alert("解锁所有应用", isPresented: $showUnlockConfirm) {
                Button("取消", role: .cancel) { }
                Button("解锁", role: .destructive) {
                    model.unblockAllApps()
                }
            } message: {
                Text("解锁后，这些应用将可以正常打开。确定要解锁 \(model.selection.applicationTokens.count) 个应用吗？")
            }
        }
    }
    
    // MARK: - 状态卡片
    private var statusCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.selection.applicationTokens.isEmpty ? "未锁定任何应用" : "已保护 \(model.selection.applicationTokens.count) 个应用")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        Text(model.selection.applicationTokens.isEmpty ? "选择应用开始保护" : "点击下方按钮管理")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(model.selection.applicationTokens.isEmpty ? Color(.systemGray5) : Color.lockerGreen.opacity(0.15))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: model.selection.applicationTokens.isEmpty ? "lock.shield" : "lock.shield.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(model.selection.applicationTokens.isEmpty ? .secondary : Color.lockerGreen)
                    }
                }
            }
        }
    }
    
    // MARK: - 空状态
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // 主操作按钮
            Button {
                isPickerPresented = true
            } label: {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.lockerBlue, Color.lockerBlue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(spacing: 4) {
                        Text("选择要锁定的应用")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Text("从系统列表中选择您想要保护的应用")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    // MARK: - 已锁定应用视图
    private var lockedAppsView: some View {
        VStack(spacing: 12) {
            // 重新选择按钮
            Button {
                isPickerPresented = true
            } label: {
                HStack {
                    Label("更换应用", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 15, weight: .medium))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
                .padding(14)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())
            
            // 锁定/解锁按钮
            Button {
                if model.selection.applicationTokens.isEmpty {
                    model.blockApps()
                } else {
                    showUnlockConfirm = true
                }
            } label: {
                HStack {
                    Spacer()
                    
                    Label(model.selection.applicationTokens.isEmpty ? "锁定选中应用" : "解锁所有应用",
                          systemImage: model.selection.applicationTokens.isEmpty ? "lock.fill" : "lock.open")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(model.selection.applicationTokens.isEmpty ? Color.lockerBlue : Color.lockerOrange)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}

// MARK: - 按钮缩放效果
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
