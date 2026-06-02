import SwiftUI
import FamilyControls

struct HomeView: View {
    @State private var isPresentingPicker = false
    @State private var selection = FamilyActivitySelection()
    @State private var showBlockAlert = false
    @State private var isBlocked = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: isBlocked ? "lock.shield.fill" : "lock.shield")
                    .font(.system(size: 80))
                    .foregroundColor(isBlocked ? .green : .blue)
                
                Text(isBlocked ? "应用已锁定" : "选择要锁定的应用")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(isBlocked ? "选中的应用已被密码保护" : "点击下方按钮选择您想要保护的应用")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if !isBlocked {
                    Button(action: {
                        isPresentingPicker = true
                    }) {
                        Label("选择应用", systemImage: "app.badge.checkmark")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                if !selection.applicationTokens.isEmpty && !isBlocked {
                    Button(action: {
                        showBlockAlert = true
                    }) {
                        Label("锁定选中的应用", systemImage: "lock.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .alert("锁定应用", isPresented: $showBlockAlert) {
                        Button("取消", role: .cancel) { }
                        Button("锁定") {
                            blockApps()
                        }
                    } message: {
                        Text("锁定后，这些应用需要密码才能打开。确定要锁定 \(selection.applicationTokens.count) 个应用吗？")
                    }
                }
                
                if isBlocked {
                    Button(action: {
                        unblockApps()
                    }) {
                        Label("解锁所有应用", systemImage: "lock.open")
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
            .navigationTitle("应用锁")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: {
                // 打开设置页面
            }) {
                Image(systemName: "gearshape")
            })
            .sheet(isPresented: $isPresentingPicker) {
                FamilyActivityPicker(selection: $selection)
            }
        }
    }
    
    func blockApps() {
        // 这里应该调用AppBlockerModel来锁定应用
        // 暂时只是模拟
        isBlocked = true
        print("Blocking \(selection.applicationTokens.count) apps")
    }
    
    func unblockApps() {
        // 这里应该调用AppBlockerModel来解锁应用
        isBlocked = false
        selection = FamilyActivitySelection()
        print("Unblocking all apps")
    }
}

#Preview {
    HomeView()
}
