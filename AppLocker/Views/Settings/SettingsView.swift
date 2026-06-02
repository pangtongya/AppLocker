import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @State private var showPasswordSetup = false
    @State private var showRemovePasswordAlert = false
    @State private var isFaceIDEnabled = false
    
    var body: some View {
        let security = SecurityManager.shared
        
        NavigationStack {
            List {
                Section(header: Text("安全设置")) {
                    Toggle(isOn: $isFaceIDEnabled) {
                        Label("Face ID", systemImage: "faceid")
                    }
                    .onChange(of: isFaceIDEnabled) { newValue in
                        Task {
                            if newValue {
                                let success = await security.enableFaceID()
                                if !success {
                                    isFaceIDEnabled = false
                                }
                            } else {
                                security.disableFaceID()
                            }
                        }
                    }
                    
                    if !isFaceIDEnabled {
                        if security.isPasswordSet {
                            Button(action: {
                                showPasswordSetup = true
                            }) {
                                Label("更改密码", systemImage: "lock.rotation")
                            }
                            .sheet(isPresented: $showPasswordSetup) {
                                PasswordSetupView()
                            }
                            
                            Button(action: {
                                showRemovePasswordAlert = true
                            }) {
                                Label("移除密码", systemImage: "lock.open")
                                    .foregroundColor(.red)
                            }
                            .alert("移除密码", isPresented: $showRemovePasswordAlert) {
                                Button("取消", role: .cancel) { }
                                Button("移除", role: .destructive) {
                                    UserDefaults.standard.removeObject(forKey: "AppLockerPassword")
                                }
                            } message: {
                                Text("移除密码后，锁定应用将不再需要密码验证。确定要移除密码吗？")
                            }
                        } else {
                            Button(action: {
                                showPasswordSetup = true
                            }) {
                                Label("设置密码", systemImage: "lock")
                            }
                            .sheet(isPresented: $showPasswordSetup) {
                                PasswordSetupView()
                            }
                        }
                    }
                }
                
                Section(header: Text("关于")) {
                    HStack {
                        Label("版本", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://pangtongya.github.io/AppLocker/")!) {
                        Label("隐私政策", systemImage: "doc.text")
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isFaceIDEnabled = security.isFaceIDEnabled
            }
        }
    }
}

struct PasswordSetupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("设置密码")) {
                    SecureField("输入密码", text: $password)
                    SecureField("确认密码", text: $confirmPassword)
                }
                
                if showError {
                    Text("密码不一致，请重试")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Section {
                    Button("保存") {
                        if password == confirmPassword && !password.isEmpty {
                            SecurityManager.shared.setPassword(password)
                            dismiss()
                        } else {
                            showError = true
                        }
                    }
                }
            }
            .navigationTitle("设置密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
