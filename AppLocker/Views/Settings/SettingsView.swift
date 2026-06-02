import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @State private var isPasswordEnabled = false
    @State private var isFaceIDEnabled = false
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPasswordSetup = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("安全设置")) {
                    Toggle(isOn: $isFaceIDEnabled) {
                        Label("Face ID", systemImage: "faceid")
                    }
                    .onChange(of: isFaceIDEnabled) { newValue in
                        if newValue {
                            authenticateWithFaceID()
                        }
                    }
                    
                    if !isFaceIDEnabled {
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
        }
    }
    
    func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, 
                               localizedReason: "使用Face ID保护应用锁") { success, error in
                DispatchQueue.main.async {
                    if !success {
                        isFaceIDEnabled = false
                    }
                }
            }
        } else {
            isFaceIDEnabled = false
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
                            // 保存密码
                            UserDefaults.standard.set(password, forKey: "AppLockerPassword")
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
