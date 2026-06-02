import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content
    @Environment(\.colorScheme) var colorScheme
    
    var cornerRadius: CGFloat = 20
    var shadowRadius: CGFloat = 10
    
    init(cornerRadius: CGFloat = 20, shadowRadius: CGFloat = 10, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background {
                ZStack {
                    // 毛玻璃效果
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // 渐变叠加
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(colorScheme == .dark ? 0.05 : 0.15),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // 边框
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            Color(.separator),
                            lineWidth: colorScheme == .dark ? 0.5 : 0.3
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: .black.opacity(colorScheme == .dark ? 0.4 : 0.08),
                radius: shadowRadius,
                x: 0,
                y: 4
            )
    }
}
