import SwiftUI
import LocalAuthentication
import LocalAuthentication

struct SettingsView: View {
    @Environment(AppLockerModel.self) var model
    @State private var isFaceIDEnabled = false
    @State private var showPasswordSheet = false
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                List {
                    // 安全设置区
                    Section {
                        if !isPasswordSet {
                            Button {
                                showPasswordSheet = true
                            } label: {
                                HStack {
                                    Label("设置密码", systemImage: "key.fill")
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            HStack {
                                Label("密码保护", systemImage: "key.fill")
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Text("已设置")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if isFaceIDAvailable {
                            Toggle(isOn: $isFaceIDEnabled) {
                                Label("Face ID", systemImage: "faceid")
                            }
                            .onChange(of: isFaceIDEnabled) { _, newValue in
                                if newValue {
                                    enableFaceID()
                                } else {
                                    disableFaceID()
                                }
                            }
                        }
                    } header: {
                        Text("安全设置")
                    } footer: {
                        Text("启用后，打开被锁定的应用需要验证身份")
                    }
                    
                    // 数据管理区
                    Section {
                        Button(role: .destructive) {
                            showResetAlert = true
                        } label: {
                            HStack {
                                Label("重置所有设置", systemImage: "arrow.counterclockwise")
                                    .foregroundStyle(.red)
                                
                                Spacer()
                            }
                        }
                    } footer: {
                        Text("这将清除所有锁定设置和应用数据")
                    }
                    
                    // 关于区
                    Section {
                        HStack {
                            Label("版本", systemImage: "info.circle")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Text("1.0")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.grouped)
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPasswordSheet) {
                PasswordSetupSheet()
            }
            .alert("重置确认", isPresented: $showResetAlert) {
                Button("取消", role: .cancel) { }
                Button("重置", role: .destructive) {
                    model.unblockAllApps()
                }
            } message: {
                Text("确定要重置所有设置吗？这将解锁所有应用并清除数据。")
            }
            .onAppear {
                checkFaceIDStatus()
            }
        }
    }
    
    private var isPasswordSet: Bool {
        UserDefaults.standard.string(forKey: "AppLockerPassword") != nil
    }
    
    private var isFaceIDAvailable: Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    private func checkFaceIDStatus() {
        isFaceIDEnabled = UserDefaults.standard.bool(forKey: "FaceIDEnabled")
    }
    
    private func enableFaceID() {
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                             localizedReason: "启用 Face ID 保护") { success, error in
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

struct PasswordSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 图标
                ZStack {
                    Circle()
                        .fill(Color.lockerBlue.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "key.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.lockerBlue)
                }
                .padding(.top, 32)
                
                // 标题
                VStack(spacing: 8) {
                    Text("设置密码")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("设置密码后，打开被锁定的应用需要输入密码")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // 输入框
                VStack(spacing: 12) {
                    SecureField("输入密码", text: $password)
                        .font(.system(size: 17))
                        .padding(14)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    SecureField("确认密码", text: $confirmPassword)
                        .font(.system(size: 17))
                        .padding(14)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.top, 12)
                
                if showError {
                    Text("密码不一致，请重试")
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                }
                
                Spacer()
                
                // 保存按钮
                Button {
                    if password == confirmPassword && !password.isEmpty {
                        UserDefaults.standard.set(password, forKey: "AppLockerPassword")
                        dismiss()
                    } else {
                        showError = true
                    }
                } label: {
                    Text("保存")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.lockerBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 24)
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
