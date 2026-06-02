import SwiftUI
import FamilyControls

struct HomeView: View {
    @State private var isPresentingPicker = false
    @State private var showSettings = false
    @State private var showSecurityAlert = false
    
    var body: some View {
        let model = AppBlockerModel.shared
        let security = SecurityManager.shared
        
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: model.selection.applicationTokens.isEmpty ? "lock.shield" : "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(model.selection.applicationTokens.isEmpty ? .blue : .green)
                
                Text(model.selection.applicationTokens.isEmpty ? "home_select_apps_title" : "home_apps_locked_title")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(model.selection.applicationTokens.isEmpty ? "home_select_apps_subtitle" : "home_apps_locked_subtitle")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if model.selection.applicationTokens.isEmpty {
                    Button(action: {
                        isPresentingPicker = true
                    }) {
                        Label("home_select_apps_button", systemImage: "app.badge.checkmark")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                if !model.selection.applicationTokens.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("home_locked_apps_header")
                            .font(.headline)
                        
                        Text(String(format: NSLocalizedString("home_locked_apps_count", comment: ""), model.selection.applicationTokens.count))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Button(action: {
                        // 调用model.blockSelectedApps()来锁定应用
                        if security.isSecuritySetUp() {
                            model.blockSelectedApps()
                        } else {
                            showSecurityAlert = true
                        }
                    }) {
                        Label("home_lock_apps_button", systemImage: "lock.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .alert("alert_security_title", isPresented: $showSecurityAlert) {
                        Button("alert_security_cancel", role: .cancel) { }
                        Button("alert_security_settings") {
                            showSettings = true
                        }
                    } message: {
                        Text("alert_security_message")
                    }
                    
                    Button(action: {
                        // 解锁所有应用
                        model.unblockAllApps()
                    }) {
                        Label("home_unlock_apps_button", systemImage: "lock.open")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("app_title")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: {
                showSettings = true
            }) {
                Image(systemName: "gearshape")
            })
            .sheet(isPresented: $isPresentingPicker) {
                FamilyActivityPicker(selection: Binding(
                    get: { model.selection },
                    set: { model.selection = $0 }
                ))
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                model.loadSelection()
            }
        }
    }
}

#Preview {
    HomeView()
}
