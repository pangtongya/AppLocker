import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.bottom, 20)
                
                Text("应用锁")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("保护您的隐私应用")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .navigationTitle("应用锁")
        }
    }
}

#Preview {
    ContentView()
}
