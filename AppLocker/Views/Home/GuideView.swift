import SwiftUI

struct GuideView: View {
    @State private var currentPage = 0
    @Environment(\.dismiss) var dismiss
    
    let pages: [GuidePage] = [
        GuidePage(
            icon: "lock.shield.fill",
            title: "guide_welcome_title",
            description: "guide_welcome_desc"
        ),
        GuidePage(
            icon: "checkmark.shield.fill",
            title: "guide_authorize_title",
            description: "guide_authorize_desc"
        ),
        GuidePage(
            icon: "key.fill",
            title: "guide_security_title",
            description: "guide_security_desc"
        ),
        GuidePage(
            icon: "app.badge.checkmark",
            title: "guide_select_title",
            description: "guide_select_desc"
        ),
        GuidePage(
            icon: "lock.fill",
            title: "guide_lock_title",
            description: "guide_lock_desc"
        )
    ]
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    GuidePageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
            Spacer()
            
            Button(action: {
                if currentPage < pages.count - 1 {
                    currentPage += 1
                } else {
                    // 最后一页，完成引导
                    UserDefaults.standard.set(true, forKey: "HasSeenGuide")
                    dismiss()
                }
            }) {
                Text(currentPage < pages.count - 1 ? "guide_next_button" : "guide_get_started_button")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }
}

struct GuidePage {
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
}

struct GuidePageView: View {
    let page: GuidePage
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: page.icon)
                .font(.system(size: 100))
                .foregroundColor(.blue)
            
            Text(page.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    GuideView()
}
