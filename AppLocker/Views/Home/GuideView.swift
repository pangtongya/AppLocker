import SwiftUI

struct GuideView: View {
    @State private var currentPage = 0
    @Environment(\.dismiss) var dismiss
    
    let pages: [GuidePage] = [
        GuidePage(
            icon: "lock.shield.fill",
            title: "欢迎使用应用锁",
            description: "为您的隐私应用添加密码或Face ID保护，防止他人未经授权访问。"
        ),
        GuidePage(
            icon: "checkmark.shield.fill",
            title: "授权屏幕使用时间",
            description: "应用需要您的授权才能管理应用访问权限。请在系统提示中允许授权。"
        ),
        GuidePage(
            icon: "key.fill",
            title: "设置安全验证",
            description: "前往设置页面，设置密码或启用Face ID，确保只有您可以解锁应用。"
        ),
        GuidePage(
            icon: "app.badge.checkmark",
            title: "选择要锁定的应用",
            description: "点击主页面的「选择应用」按钮，从列表中选择您想要保护的应用。"
        ),
        GuidePage(
            icon: "lock.fill",
            title: "锁定应用",
            description: "选择完应用后，点击「锁定应用」按钮。现在这些应用需要验证才能打开！"
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
                Text(currentPage < pages.count - 1 ? "下一步" : "开始使用")
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
    let title: String
    let description: String
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
