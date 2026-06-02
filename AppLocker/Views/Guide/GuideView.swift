import SwiftUI

struct GuideView: View {
    @Environment(AppLockerModel.self) var model
    @State private var currentPage = 0
    
    let pages: [GuidePage] = [
        GuidePage(
            icon: "lock.shield.fill",
            title: "guide_welcome_title",
            subtitle: "guide_welcome_subtitle",
            color: .lockerBlue
        ),
        GuidePage(
            icon: "checkmark.shield.fill",
            title: "guide_auth_title",
            subtitle: "guide_auth_subtitle",
            color: .lockerGreen
        ),
        GuidePage(
            icon: "app.badge.checkmark",
            title: "guide_select_title",
            subtitle: "guide_select_subtitle",
            color: .lockerOrange
        ),
        GuidePage(
            icon: "lock.fill",
            title: "guide_lock_title",
            subtitle: "guide_lock_subtitle",
            color: .lockerBlue
        ),
        GuidePage(
            icon: "hand.wave.fill",
            title: "guide_ready_title",
            subtitle: "guide_ready_subtitle",
            color: .lockerGreen
        )
    ]
    
    var body: some View {
        ZStack {
            // 背景
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 页面内容
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        GuidePageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // 页面指示器
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? pages[currentPage].color : Color(.systemGray4))
                            .frame(width: 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // 按钮
                VStack(spacing: 12) {
                    if currentPage < pages.count - 1 {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                currentPage += 1
                            }
                        } label: {
                            Text("guide_next")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(pages[currentPage].color)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button {
                            // 跳过引导
                            model.completeOnboarding()
                        } label: {
                            Text("guide_skip")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Button {
                            model.completeOnboarding()
                        } label: {
                            Text("guide_start")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(pages[currentPage].color)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }
}

struct GuidePageView: View {
    let page: GuidePage
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 图标
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 140, height: 140)
                
                Circle()
                    .fill(page.color.opacity(0.08))
                    .frame(width: 180, height: 180)
                
                Image(systemName: page.icon)
                    .font(.system(size: 56))
                    .foregroundStyle(page.color)
            }
            
            // 文字
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(page.subtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct GuidePage {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
}

#Preview {
    GuideView()
}
