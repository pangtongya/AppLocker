import SwiftUI
import FamilyControls

struct HomeView: View {
    @State private var isPresentingPicker = false
    
    var body: some View {
        let model = AppBlockerModel.shared
        
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: model.selection.applicationTokens.isEmpty ? "lock.shield" : "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(model.selection.applicationTokens.isEmpty ? .blue : .green)
                
                Text(model.selection.applicationTokens.isEmpty ? "选择要锁定的应用" : "应用已锁定")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(model.selection.applicationTokens.isEmpty ? "点击下方按钮选择您想要保护的应用" : "选中的应用已被保护")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if model.selection.applicationTokens.isEmpty {
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
                
                if !model.selection.applicationTokens.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("已锁定的应用:")
                            .font(.headline)
                        
                        Text("\(model.selection.applicationTokens.count) 个应用")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Button(action: {
                        // 调用model.blockSelectedApps()来锁定应用
                        model.blockSelectedApps()
                    }) {
                        Label("锁定应用", systemImage: "lock.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        // 解锁所有应用
                        model.unblockAllApps()
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
                FamilyActivityPicker(selection: Binding(
                    get: { model.selection },
                    set: { model.selection = $0 }
                ))
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
