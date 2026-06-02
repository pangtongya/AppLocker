import SwiftUI

struct GuideView: View {
    @Environment(AppLockerModel.self) var model
    @State private var currentPage = 0
    @State private var showAuthAlert = false
    @State private var authErrorMsg = ""
    
    let pages: [GuidePage] = [
        GuidePage(icon: "lock.shield.fill", titleKey: "guide_welcome_title", subtitleKey: "guide_welcome_subtitle", color: .lockerBlue),
        GuidePage(icon: "checkmark.shield.fill", titleKey: "guide_auth_title", subtitleKey: "guide_auth_subtitle", color: .lockerGreen),
        GuidePage(icon: "app.badge.checkmark", titleKey: "guide_select_title", subtitleKey: "guide_select_subtitle", color: .lockerOrange),
        GuidePage(icon: "lock.fill", titleKey: "guide_lock_title", subtitleKey: "guide_lock_subtitle", color: .lockerBlue),
        GuidePage(icon: "hand.wave.fill", titleKey: "guide_ready_title", subtitleKey: "guide_ready_subtitle", color: .lockerGreen)
    ]
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    pages[currentPage].color.opacity(0.08),
                    Color(.systemGroupedBackground),
                    Color(.systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 页面内容
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        GuidePageView(page: pages[index], isActive: currentPage == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: currentPage)
                
                // 底部操作区
                bottomSection
            }
        }
        .alert("需要授权", isPresented: $showAuthAlert) {
            Button("重试") { requestAuth() }
            Button("跳过", role: .cancel) { advancePage() }
        } message: {
            Text(authErrorMsg.isEmpty ? "请在系统弹窗中允许「应用锁」访问屏幕使用时间" : authErrorMsg)
        }
    }
    
    // MARK: - 底部操作区
    private var bottomSection: some View {
        VStack(spacing: 16) {
            // 页面指示器
            HStack(spacing: 6) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(currentPage == index ? pages[currentPage].color : Color(.systemGray4))
                        .frame(width: currentPage == index ? 20 : 6, height: 6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
                }
            }
            .padding(.top, 16)
            
            // 主按钮
            if currentPage < pages.count - 1 {
                Button { handleNext() } label: {
                    HStack(spacing: 8) {
                        Text(currentPage == pages.count - 2 ? "guide_start" : "guide_next")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [pages[currentPage].color, pages[currentPage].color.opacity(0.85)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: pages[currentPage].color.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
                
                // 跳过按钮（不在第一页显示）
                if currentPage > 0 {
                    Button { model.completeOnboarding() } label: {
                        Text("guide_skip")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                // 最后一页：开始使用
                Button { model.completeOnboarding() } label: {
                    HStack(spacing: 8) {
                        Text("guide_start")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [pages[currentPage].color, pages[currentPage].color.opacity(0.85)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: pages[currentPage].color.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }
    
    // MARK: - 处理下一步
    private func handleNext() {
        if currentPage == 1 {
            // 授权页面：触发系统授权
            requestAuth()
        } else {
            advancePage()
        }
    }
    
    private func requestAuth() {
        Task {
            await model.requestAuthorization()
            if model.isAuthorized {
                advancePage()
            } else {
                authErrorMsg = "授权失败，您可以稍后在系统设置中重新授权"
                showAuthAlert = true
            }
        }
    }
    
    private func advancePage() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            currentPage += 1
        }
    }
}

// MARK: - 引导页内容视图
struct GuidePageView: View {
    let page: GuidePage
    let isActive: Bool
    
    @State private var iconScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // 图标区
            ZStack {
                // 外层光晕
                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 180, height: 180)
                    .blur(radius: 16)
                
                // 中层光圈
                Circle()
                    .stroke(page.color.opacity(0.2), lineWidth: 1)
                    .frame(width: 150, height: 150)
                
                // 主图标容器
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [page.color.opacity(0.3), page.color.opacity(0.05)],
                                center: .topLeading,
                                startRadius: 10,
                                endRadius: 70
                            )
                        )
                        .frame(width: 110, height: 110)
                    
                    Image(systemName: page.icon)
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [page.color, page.color.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            .scaleEffect(iconScale)
            .onChange(of: isActive) { _, active in
                if active {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        iconScale = 1.0
                    }
                } else {
                    iconScale = 0.5
                }
            }
            .onAppear {
                if isActive {
                    iconScale = 1.0
                }
            }
            
            // 文字区
            VStack(spacing: 14) {
                Text(page.titleKey)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(page.subtitleKey)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 20)
            }
            .opacity(textOpacity)
            .onChange(of: isActive) { _, active in
                if active {
                    withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                        textOpacity = 1.0
                    }
                } else {
                    textOpacity = 0
                }
            }
            .onAppear {
                if isActive {
                    textOpacity = 1.0
                }
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct GuidePage {
    let icon: String
    let titleKey: String
    let subtitleKey: String
    let color: Color
}

#Preview {
    GuideView()
}
