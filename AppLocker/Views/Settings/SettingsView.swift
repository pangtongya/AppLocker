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
                Section(header: Text("settings_security_section")) {
                    Toggle(isOn: $isFaceIDEnabled) {
                        Label("settings_face_id", systemImage: "faceid")
                    }
                    .onChange(of: isFaceIDEnabled) { _, newValue in
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
                                Label("settings_change_password", systemImage: "lock.rotation")
                            }
                            .sheet(isPresented: $showPasswordSetup) {
                                PasswordSetupView()
                            }
                            
                            Button(action: {
                                showRemovePasswordAlert = true
                            }) {
                                Label("settings_remove_password", systemImage: "lock.open")
                                    .foregroundColor(.red)
                            }
                            .alert("alert_remove_password_title", isPresented: $showRemovePasswordAlert) {
                                Button("alert_remove_password_cancel", role: .cancel) { }
                                Button("alert_remove_password_remove", role: .destructive) {
                                    UserDefaults.standard.removeObject(forKey: "AppLockerPassword")
                                }
                            } message: {
                                Text("alert_remove_password_message")
                            }
                        } else {
                            Button(action: {
                                showPasswordSetup = true
                            }) {
                                Label("settings_set_password", systemImage: "lock")
                            }
                            .sheet(isPresented: $showPasswordSetup) {
                                PasswordSetupView()
                            }
                        }
                    }
                }
                
                Section(header: Text("settings_about_section")) {
                    HStack {
                        Label("settings_version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://pangtongya.github.io/AppLocker/")!) {
                        Label("settings_privacy_policy", systemImage: "doc.text")
                    }
                }
            }
            .navigationTitle("settings_title")
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
                Section(header: Text("password_setup_section")) {
                    SecureField("password_setup_enter", text: $password)
                    SecureField("password_setup_confirm", text: $confirmPassword)
                }
                
                if showError {
                    Text("password_setup_error")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Section {
                    Button("password_setup_save") {
                        if password == confirmPassword && !password.isEmpty {
                            SecurityManager.shared.setPassword(password)
                            dismiss()
                        } else {
                            showError = true
                        }
                    }
                }
            }
            .navigationTitle("password_setup_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("password_setup_cancel") {
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
