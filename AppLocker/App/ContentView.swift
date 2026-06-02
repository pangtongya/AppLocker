import SwiftUI

struct ContentView: View {
    @State private var showGuide = !UserDefaults.standard.bool(forKey: "HasSeenGuide")
    
    var body: some View {
        HomeView()
            .sheet(isPresented: $showGuide, onDismiss: {
                showGuide = false
            }) {
                GuideView()
            }
    }
}

#Preview {
    ContentView()
}
