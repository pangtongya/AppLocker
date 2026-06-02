import SwiftUI

@main
struct AppLockerApp: App {
    @State private var model = AppLockerModel.shared
    
    var body: some Scene {
        WindowGroup {
            if model.isOnboardingComplete {
                ContentView()
                    .environment(model)
            } else {
                GuideView()
                    .environment(model)
            }
        }
    }
}
