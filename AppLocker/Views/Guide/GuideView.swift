import SwiftUI

struct GuideView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var shieldManager: ShieldManager
    @State private var currentPage = 0
    @State private var showAuthAlert = false
    @State private var authErrorMsg = ""
    @State private var isAuthorizing = false

    let pages: [GuidePage] = [
        GuidePage(icon: "lock.shield.fill", titleKey: "guide_welcome_title", subtitleKey: "guide_welcome_subtitle", color: .lockerBlue),
        GuidePage(icon: "checkmark.shield.fill", titleKey: "guide_auth_title", subtitleKey: "guide_auth_subtitle", color: .lockerGreen),
        GuidePage(icon: "app.badge.checkmark", titleKey: "guide_select_title", subtitleKey: "guide_select_subtitle", color: .lockerOrange),
        GuidePage(icon: "lock.fill", titleKey: "guide_lock_title", subtitleKey: "guide_lock_subtitle", color: .lockerBlue),
        GuidePage(icon: "hand.wave.fill", titleKey: "guide_ready_title", subtitleKey: "guide_ready_subtitle", color: .lockerGreen)
    ]

    var body: some View {
        ZStack {
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
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        GuidePageView(page: pages[index], isActive: currentPage == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: currentPage)

                bottomSection
            }
        }
        .alert(LocalizedStringKey("guide_auth_alert_title"), isPresented: $showAuthAlert) {
            Button(LocalizedStringKey("guide_auth_go_settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(LocalizedStringKey("guide_cancel"), role: .cancel) { }
        } message: {
            Text(authErrorMsg)
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

            if isAuthorizing {
                ProgressView()
                    .padding(.vertical, 8)
            }

            if currentPage < pages.count - 1 {
                Button { handleNext() } label: {
                    HStack(spacing: 8) {
                        if isAuthorizing {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(authButtonTitle)
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
                .disabled(isAuthorizing)

                if currentPage > 1 {
                    Button {
                        appState.hasCompletedOnboarding = true
                        appState.save()
                    } label: {
                        Text(LocalizedStringKey("guide_skip"))
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Button {
                    appState.hasCompletedOnboarding = true
                    appState.save()
                } label: {
                    HStack(spacing: 8) {
                        Text(LocalizedStringKey("guide_start"))
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
    private var authButtonTitle: String {
        if currentPage == 1 {
            switch shieldManager.authorizationStatus {
            case .approved:
                return NSLocalizedString("guide_auth_approved", comment: "")
            case .denied:
                return NSLocalizedString("guide_auth_denied", comment: "")
            case .notDetermined:
                return NSLocalizedString("guide_auth_request", comment: "")
            }
        }
        return currentPage == pages.count - 2 ? NSLocalizedString("guide_start_use", comment: "") : NSLocalizedString("guide_next", comment: "")
    }

    private func handleNext() {
        if currentPage == 1 {
            switch shieldManager.authorizationStatus {
            case .approved:
                advancePage()
            case .denied:
                // 已被拒绝，引导用户去设置
                authErrorMsg = NSLocalizedString("guide_auth_denied_msg", comment: "")
                showAuthAlert = true
            case .notDetermined:
                requestAuth()
            }
        } else {
            advancePage()
        }
    }

    private func requestAuth() {
        isAuthorizing = true
        Task {
            let authorized = await shieldManager.requestAuthorization()
            isAuthorizing = false
            if authorized {
                advancePage()
            } else {
                authErrorMsg = NSLocalizedString("guide_auth_failed_msg", comment: "")
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

            ZStack {
                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 180, height: 180)
                    .blur(radius: 16)

                Circle()
                    .stroke(page.color.opacity(0.2), lineWidth: 1)
                    .frame(width: 150, height: 150)

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

            VStack(spacing: 14) {
                Text(LocalizedStringKey(page.titleKey))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)

                Text(LocalizedStringKey(page.subtitleKey))
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
        .environmentObject(AppState.shared)
        .environmentObject(ShieldManager.shared)
}
