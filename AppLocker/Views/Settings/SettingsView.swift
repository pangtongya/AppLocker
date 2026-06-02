import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @Environment(AppLockerModel.self) var model
    @State private var isFaceIDEnabled = false
    @State private var showPasswordSheet = false
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // 顶部图标
                        topIconSection

                        // 安全设置卡片
                        securityCard

                        // 数据管理卡片
                        dataCard

                        // 关于卡片
                        aboutCard

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPasswordSheet) {
                PasswordSetupSheet()
            }
            .alert("重置确认", isPresented: $showResetConfirm) {
                Button("取消", role: .cancel) { }
                Button("重置", role: .destructive) {
                    model.unblockAllApps()
                    UserDefaults.standard.removeObject(forKey: "AppLockerPassword")
                    UserDefaults.standard.removeObject(forKey: "FaceIDEnabled")
                    isFaceIDEnabled = false
                }
            } message: {
                Text("这将清除所有设置，解锁全部应用。确定要继续吗？")
            }
            .onAppear {
                isFaceIDEnabled = UserDefaults.standard.bool(forKey: "FaceIDEnabled")
            }
        }
    }

    // MARK: - 顶部图标
    private var topIconSection: some View {
        ZStack {
            Circle()
                .fill(Color.lockerBlue.opacity(0.1))
                .frame(width: 100, height: 100)
                .blur(radius: 12)

            Image(systemName: "gearshape.fill")
                .font(.system(size: 36))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.lockerBlue, .lockerBlue.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .frame(height: 100)
    }

    // MARK: - 安全设置卡片
    private var securityCard: some View {
        GlassCard(cornerRadius: 16) {
            VStack(spacing: 0) {
                // 密码设置行
                if !isPasswordSet {
                    Button { showPasswordSheet = true } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.lockerBlue)
                                    .frame(width: 32, height: 32)
                                Image(systemName: "key.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("密码保护")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text("未设置")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.vertical, 4)

                    Divider()
                        .padding(.leading, 44)
                } else {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.lockerGreen)
                                .frame(width: 32, height: 32)
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("密码保护")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text("已设置")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)

                    Divider()
                        .padding(.leading, 44)
                }

                // Face ID 行
                if isFaceIDAvailable {
                    Toggle(isOn: $isFaceIDEnabled) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.lockerOrange)
                                    .frame(width: 32, height: 32)
                                Image(systemName: "faceid")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Face ID")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text(isFaceIDEnabled ? "已启用" : "未启用")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .lockerGreen))
                    .onChange(of: isFaceIDEnabled) { _, newValue in
                        if newValue {
                            enableFaceID()
                        } else {
                            disableFaceID()
                        }
                    }
                }
            }
            .padding(4)
        }
    }

    // MARK: - 数据管理卡片
    private var dataCard: some View {
        GlassCard(cornerRadius: 16) {
            VStack(spacing: 0) {
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.lockerRed)
                                .frame(width: 32, height: 32)
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("重置所有设置")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.red)
                            Text("解锁全部应用并清除数据")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.vertical, 4)
            }
            .padding(4)
        }
    }

    // MARK: - 关于卡片
    private var aboutCard: some View {
        GlassCard(cornerRadius: 16) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(.systemGray4))
                            .frame(width: 32, height: 32)
                        Image(systemName: "info")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("版本")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("1.0")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .padding(4)
        }
    }

    // MARK: - 辅助方法
    private var isPasswordSet: Bool {
        UserDefaults.standard.string(forKey: "AppLockerPassword") != nil
    }

    private var isFaceIDAvailable: Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    private func enableFaceID() {
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                             localizedReason: "启用 Face ID 保护") { success, _ in
            Task { @MainActor in
                if success {
                    UserDefaults.standard.set(true, forKey: "FaceIDEnabled")
                } else {
                    isFaceIDEnabled = false
                }
            }
        }
    }

    private func disableFaceID() {
        UserDefaults.standard.set(false, forKey: "FaceIDEnabled")
    }
}

// MARK: - 密码设置表单
struct PasswordSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var confirm = ""
    @State private var showMismatch = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 28) {
                    // 图标
                    ZStack {
                        Circle()
                            .fill(Color.lockerBlue.opacity(0.12))
                            .frame(width: 88, height: 88)
                        Image(systemName: "key.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.lockerBlue)
                    }
                    .padding(.top, 24)

                    // 标题
                    VStack(spacing: 8) {
                        Text("设置密码")
                            .font(.system(size: 24, weight: .bold))
                        Text("设置后，打开被锁定的应用需要输入密码")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // 输入区
                    VStack(spacing: 12) {
                        SecureField("输入密码", text: $password)
                            .font(.system(size: 17))
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        SecureField("确认密码", text: $confirm)
                            .font(.system(size: 17))
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    if showMismatch {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("密码不一致，请重试")
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                        .transition(.opacity)
                    }

                    Spacer()

                    // 保存按钮
                    Button {
                        guard password == confirm, !password.isEmpty else {
                            withAnimation { showMismatch = true }
                            return
                        }
                        UserDefaults.standard.set(password, forKey: "AppLockerPassword")
                        dismiss()
                    } label: {
                        Text("保存")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(password.isEmpty ? Color.gray : Color.lockerBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: password.isEmpty ? .clear : Color.lockerBlue.opacity(0.3),
                                    radius: 8, x: 0, y: 4)
                    }
                    .disabled(password.isEmpty)
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("设置密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
