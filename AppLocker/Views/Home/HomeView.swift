import SwiftUI
import FamilyControls

struct HomeView: View {
    @State private var isPresentingPicker = false
    @State private var selection = FamilyActivitySelection()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("选择要锁定的应用")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("点击下方按钮选择您想要保护的应用")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
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
                .sheet(isPresented: $isPresentingPicker) {
                    FamilyActivityPicker(selection: $selection)
                }
                
                if !selection.applicationTokens.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("已选择的应用:")
                            .font(.headline)
                        
                        Text("\(selection.applicationTokens.count) 个应用")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("应用锁")
        }
    }
}

#Preview {
    HomeView()
}
