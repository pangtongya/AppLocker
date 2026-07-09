import SwiftUI

/// 专注完成庆祝动画
struct CelebrationView: View {
    let onDismiss: () -> Void

    @State private var showCheckmark = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // 背景模糊
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .opacity(opacity)

            VStack(spacing: 24) {
                Spacer()

                // 勾号动画
                ZStack {
                    Circle()
                        .fill(Color.lockerGreen.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showCheckmark ? 1.0 : 0.5)
                        .opacity(showCheckmark ? 1.0 : 0)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.lockerGreen)
                        .scaleEffect(showCheckmark ? 1.0 : 0.3)
                        .rotationEffect(.degrees(showCheckmark ? 0 : -30))
                }

                Text(LocalizedStringKey("celebration_title"))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .opacity(showCheckmark ? 1 : 0)
                    .offset(y: showCheckmark ? 0 : 20)

                Text(LocalizedStringKey("celebration_subtitle"))
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(showCheckmark ? 1 : 0)
                    .offset(y: showCheckmark ? 0 : 20)

                Spacer()

                Button(action: onDismiss) {
                    Text(LocalizedStringKey("celebration_dismiss"))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.lockerBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .opacity(showCheckmark ? 1 : 0)
            }
            .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                opacity = 1
                scale = 1.0
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                showCheckmark = true
            }
        }
    }
}

#Preview {
    CelebrationView(onDismiss: {})
}
