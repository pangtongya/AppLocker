// HomeView.swift
// 主屏：应用锁定启动器

import SwiftUI
import FamilyControls
import UIKit

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var lockStore: LockStore
    @EnvironmentObject var shieldManager: ShieldManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var presetStore: PresetStore

    @State private var selectedMinutes: Int = 25
    @State private var showCustomDuration = false
    @State private var customMinutes: String = ""
    @State private var isPickerPresented = false
    @State private var showUnlockAuth = false
    @State private var unlockPassword = ""
    @State private var showPasswordFail = false
    @State private var showCelebration = false
    @State private var showFocusStartAnim = false
    @State private var pendingAutoStart = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppLockerBackground()

                ScrollView {
                    VStack(spacing: 32) {
                        if lockStore.isLocking {
                            lockStatusCard
                        } else if !shieldManager.isAuthorized {
                            authRequiredCard
                        } else {
                            heroSection
                        }
                        statsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 80)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(LocalizedStringKey("home_title"))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showCustomDuration) {
            customDurationSheet
        }
        .sheet(isPresented: $isPickerPresented) {
            NavigationStack {
                FamilyActivityPicker(selection: Binding(
                    get: { shieldManager.selection },
                    set: { shieldManager.selection = $0 }
                ))
                .navigationTitle(LocalizedStringKey("home_select_apps"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(LocalizedStringKey("home_done")) {
                            // 更新计数：应用+类别+网站
                            shieldManager.lockedAppCount = shieldManager.selection.applicationTokens.count + shieldManager.selection.categoryTokens.count + shieldManager.selection.webDomainTokens.count
                            print("[HomeView] User finished selecting: \(shieldManager.lockedAppCount) items selected")
                            isPickerPresented = false
                            // 如果是从"开始专注"跳转过来的，自动开始专注
                            if pendingAutoStart && shieldManager.lockedAppCount > 0 {
                                pendingAutoStart = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                    lockStore.startLock(
                                        plannedMinutes: selectedMinutes,
                                        appCount: shieldManager.lockedAppCount
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .presentationDetents([.large])
        }
        .alert(LocalizedStringKey("home_unlock_alert_title"), isPresented: $showUnlockAuth) {
            if authManager.isFaceIDEnabled {
                Button(LocalizedStringKey("home_use_faceid")) {
                    Task { await performBiometricUnlock() }
                }
            }
            if authManager.isPasswordSet {
                SecureField(LocalizedStringKey("home_enter_password"), text: $unlockPassword)
                Button(LocalizedStringKey("home_confirm_btn")) {
                    if authManager.verifyPassword(unlockPassword) {
                        lockStore.unlockManually()
                        unlockPassword = ""
                    } else {
                        showPasswordFail = true
                        unlockPassword = ""
                    }
                }
            }
            Button(LocalizedStringKey("home_cancel"), role: .cancel) {
                unlockPassword = ""
            }
        } message: {
            Text(showPasswordFail ? LocalizedStringKey("home_password_wrong") : LocalizedStringKey("home_unlock_message"))
        }
        // 专注完成庆祝
        .overlay {
            if showCelebration {
                CelebrationView {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showCelebration = false
                    }
                }
                .transition(.opacity)
                .ignoresSafeArea()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("LockStoreDidEndLock"))) { notif in
            if let session = notif.object as? LockSession, session.wasCompleted {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.easeIn(duration: 0.3)) {
                    showCelebration = true
                }
            }
        }
    }

    // MARK: - 顶部状态区

    private var heroSection: some View {
        VStack(spacing: 24) {
            // 图标 + 标题
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.lockerBlue.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .blur(radius: 16)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(.lockerBlue)
                }

                Text(LocalizedStringKey("home_hero_title"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(LocalizedStringKey("home_hero_subtitle"))
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }

            // 专注预设
            PresetSelectorView { preset in
                selectedMinutes = preset.durationMinutes
                if preset.appTokenNames.isEmpty {
                    // 没有预设的应用选择，让用户自己选
                } else {
                    // 预设关联了应用选择（提示用户手动选择）
                }
            }

            // 时长选择
            durationPicker

            // App 选择
            appSelectionRow

            // 开始锁定按钮
            startLockButton
        }
    }

    // MARK: - 时长选择

    private var durationPicker: some View {
        VStack(spacing: 10) {
            HStack {
                Text(LocalizedStringKey("home_duration_label"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                spacing: 10
            ) {
                ForEach([25, 45, 60, 90], id: \.self) { minutes in
                    durationButton(minutes: minutes)
                }

                // 自定义按钮
                Button(action: {
                    customMinutes = selectedMinutes > 90 ? "\(selectedMinutes)" : ""
                    showCustomDuration = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: selectedMinutes > 90 ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 20))
                                                Text(selectedMinutes > 90 ? String(format: NSLocalizedString("home_selected_custom", comment: ""), selectedMinutes) : NSLocalizedString("home_custom", comment: ""))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(selectedMinutes > 90 ? .white : Color.lockerOrange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedMinutes > 90
                        ? Color.lockerBlue
                        : Color(.systemGray6)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func durationButton(minutes: Int) -> some View {
        let icons = [25: "🎯", 45: "⚡", 60: "🔥", 90: "💎"]
        let isSelected = selectedMinutes == minutes

        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedMinutes = minutes
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            VStack(spacing: 4) {
                Text(icons[minutes] ?? "⏱")
                    .font(.system(size: 20))
                Text(String(format: NSLocalizedString("home_minutes_format", comment: ""), minutes))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected
                ? Color.lockerBlue
                : Color(.systemGray6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }

    // MARK: - 自定义时长

    private var customDurationSheet: some View {
        let presetDurations = [25, 45, 60, 90, 120, 180, 240, 480]

        return NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 16) {
                    Text(LocalizedStringKey("home_custom_title"))
                        .font(.system(size: 22, weight: .bold, design: .rounded))

                    Text(String(format: NSLocalizedString("home_custom_value", comment: ""), Int(customMinutes) ?? 0))
                        .font(.system(size: 48, weight: .thin, design: .monospaced))
                        .foregroundColor(.primary)
                        .animation(.spring(), value: customMinutes)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(presetDurations, id: \.self) { duration in
                                Button(action: { customMinutes = "\(duration)" }) {
                                        Text(String(format: NSLocalizedString("home_minutes_format", comment: ""), duration))
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(Int(customMinutes) == duration ? .white : .primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Int(customMinutes) == duration
                                            ? Color.lockerBlue
                                            : Color(.systemGray6)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Stepper(value: Binding(
                        get: { Int(customMinutes) ?? 0 },
                        set: { customMinutes = "\($0)" }
                    ), in: 1...480, step: 5) {
                            Text(LocalizedStringKey("home_custom_stepper"))
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)

                                        TextField(LocalizedStringKey("home_custom_input_placeholder"), text: $customMinutes)
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .padding(16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 40)
                }

                Spacer()

                Button(action: {
                    if let mins = Int(customMinutes), mins > 0, mins <= 480 {
                        selectedMinutes = mins
                        showCustomDuration = false
                    }
                }) {
                    Text(LocalizedStringKey("home_confirm"))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.lockerBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .disabled(customMinutes.isEmpty || Int(customMinutes) == nil || Int(customMinutes)! <= 0 || Int(customMinutes)! > 480)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                                        Button(LocalizedStringKey("home_cancel")) { showCustomDuration = false }
                }
            }
        }
    }

    // MARK: - App 选择行

    private var appSelectionRow: some View {
        Button(action: {
            isPickerPresented = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.lockerBlue)
                        .frame(width: 36, height: 36)
                    Image(systemName: "app.badge.checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                                        Text(shieldManager.lockedAppCount > 0 ? String(format: NSLocalizedString("home_apps_selected", comment: ""), shieldManager.lockedAppCount) : NSLocalizedString("home_select_apps_prompt", comment: ""))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                                        Text(shieldManager.lockedAppCount > 0 ? LocalizedStringKey("home_tap_to_change") : LocalizedStringKey("home_from_system_list"))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - 开始锁定按钮

    private var startLockButton: some View {
        Button(action: {
            guard shieldManager.lockedAppCount > 0 else {
                pendingAutoStart = true
                isPickerPresented = true
                return
            }
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            lockStore.startLock(
                plannedMinutes: selectedMinutes,
                appCount: shieldManager.lockedAppCount
            )
        }) {
            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .semibold))
                                Text(String(format: NSLocalizedString("home_lock_button", comment: ""), selectedMinutes))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.lockerBlue, Color.lockerBlue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.lockerBlue.opacity(0.25), radius: 12, x: 0, y: 6)
        }
        .padding(.top, 8)
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - 授权引导卡片

    private var authRequiredCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.slash.fill")
                .font(.system(size: 40))
                .foregroundColor(.lockerOrange)

            Text(LocalizedStringKey("home_auth_required_title"))
                .font(.system(size: 18, weight: .bold, design: .rounded))

            Text(LocalizedStringKey("home_auth_required_desc"))
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Button(action: {
                Task { await shieldManager.requestAuthorization() }
            }) {
                Text(LocalizedStringKey("home_auth_request_btn"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.lockerBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if shieldManager.needsSettingsAuthorization {
                Button(action: { shieldManager.openSettings() }) {
                    Text(LocalizedStringKey("guide_auth_go_settings"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.lockerBlue)
                }
            }
        }
        .padding(24)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - 锁定状态卡

    private var lockStatusCard: some View {
        VStack(spacing: 20) {
            // 顶部状态
            HStack {
                PulseCircle()
                Text(LocalizedStringKey("home_status_locking"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.lockerGreen)
                Spacer()
            }

            if let session = lockStore.currentSession {
                // 倒计时
                VStack(spacing: 8) {
                    Text(session.formattedRemaining)
                        .font(.system(size: 48, weight: .thin, design: .monospaced))
                        .foregroundColor(.primary)
                        .monospacedDigit()

                    Text(String(format: NSLocalizedString("home_remaining", comment: ""), session.plannedMinutes))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)

                    Text(String(format: NSLocalizedString("home_apps_locked_count", comment: ""), session.appCount))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.lockerGreen)
                }

                // 进度条
                ProgressView(value: session.completionRate, total: 1.0)
                    .tint(.lockerBlue)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                // 提前解锁按钮
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if authManager.isPasswordSet || authManager.isFaceIDEnabled {
                        showPasswordFail = false
                        showUnlockAuth = true
                    } else {
                        // 没有设密码，直接解锁
                        lockStore.unlockManually()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.open")
                            .font(.system(size: 14, weight: .semibold))
                                                Text(LocalizedStringKey("home_early_unlock"))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.lockerOrange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.lockerOrange.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(24)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            // 每秒触发 UI 刷新（LockStore 的 objectWillChange 自动处理）
        }
    }

    // MARK: - 统计卡片

    private var statsSection: some View {
        VStack(spacing: 16) {
            todayStatsCard
            weekStatsCard
        }
    }

    private var todayStatsCard: some View {
        VStack(spacing: 16) {
            HStack {
                                Text(LocalizedStringKey("home_today_overview"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
            }

            HStack(spacing: 0) {
                                statItem(value: "\(lockStore.todayTotalMinutes)", unit: NSLocalizedString("home_unit_minutes", comment: ""), icon: "clock.fill", color: .lockerBlue, trend: .up)
                Divider().frame(height: 40).background(Color.gray.opacity(0.3))
                statItem(value: "\(lockStore.todaySessions.count)", unit: NSLocalizedString("home_unit_sessions", comment: ""), icon: "lock.fill", color: .lockerOrange, trend: .up)
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var weekStatsCard: some View {
        VStack(spacing: 16) {
            HStack {
                                Text(LocalizedStringKey("home_week_achievement"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                NavigationLink {
                    StatsView()
                        .environmentObject(appState)
                        .environmentObject(lockStore)
                } label: {
                                        Text(LocalizedStringKey("home_full_stats"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.lockerBlue)
                }
            }

            HStack(spacing: 0) {
                statItem(value: "\(lockStore.weekTotalMinutes)", unit: NSLocalizedString("home_unit_minutes", comment: ""), icon: "flame.fill", color: .lockerOrange, trend: .up)
                Divider().frame(height: 40).background(Color.gray.opacity(0.3))
                statItem(value: "\(lockStore.weekSessions.count)", unit: NSLocalizedString("home_unit_session_count", comment: ""), icon: "lock.fill", color: .lockerBlue, trend: .up)
                Divider().frame(height: 40).background(Color.gray.opacity(0.3))
                statItem(value: "\(lockStore.currentStreak)", unit: NSLocalizedString("home_unit_days_streak", comment: ""), icon: "bolt.fill", color: .lockerGreen, trend: lockStore.currentStreak > 0 ? .up : .neutral)
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - 统计项

    private func statItem(value: String, unit: String, icon: String, color: Color, trend: Trend = .neutral) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            HStack(spacing: 2) {
                if trend == .up {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.lockerGreen)
                }
                Text(unit)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    enum Trend {
        case up, down, neutral
    }

    // MARK: - Biometric Unlock

    private func performBiometricUnlock() async {
        let success = await authManager.verifyBiometric()
        if success {
            lockStore.unlockManually()
        }
    }
}

// MARK: - 脉冲动画圆圈

private struct PulseCircle: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.lockerGreen.opacity(0.3))
                .frame(width: 16, height: 16)
                .scaleEffect(isAnimating ? 1.5 : 1.0)
                .opacity(isAnimating ? 0.3 : 0.8)
                .animation(
                    Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: isAnimating
                )

            Circle()
                .fill(Color.lockerGreen.opacity(0.2))
                .frame(width: 10, height: 10)
        }
        .onAppear { isAnimating = true }
    }
}

// MARK: - Background

private struct AppLockerBackground: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            RadialGradient(
                colors: [Color.lockerBlue.opacity(0.08), .clear],
                center: .top,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
        .environmentObject(AppState.shared)
        .environmentObject(LockStore.shared)
        .environmentObject(ShieldManager.shared)
        .environmentObject(AuthManager.shared)
}
