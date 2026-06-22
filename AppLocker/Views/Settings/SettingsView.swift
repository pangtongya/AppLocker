// SettingsView.swift
// 设置界面

import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var lockStore: LockStore
    @EnvironmentObject var authManager: AuthManager

    @State private var showPasswordSheet = false
    @State private var showResetConfirm = false
    @State private var showGoalEditor = false
    @State private var tempGoalMinutes: Int = 150
    @State private var csvURL: URL?
    @State private var showExportSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        topIconSection

                        // 安全设置
                        securityCard

                        // 功能设置
                        featureCard

                        // 数据管理
                        dataCard

                        // 关于
                        aboutCard

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
                        .navigationTitle(LocalizedStringKey("settings_title"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPasswordSheet) {
                PasswordSetupSheet(authManager: authManager)
            }
            .sheet(isPresented: $showGoalEditor) {
                goalEditorSheet
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = csvURL {
                    ActivityView(activityItems: [url])
                }
            }
            .alert(LocalizedStringKey("reset_confirm_title"), isPresented: $showResetConfirm) {
                Button(LocalizedStringKey("password_cancel"), role: .cancel) { }
                Button(LocalizedStringKey("reset_action"), role: .destructive) {
                    // 清除当前锁定状态
                    if lockStore.isLocking {
                        lockStore.cancelLock()
                    }
                    lockStore.history = []
                    lockStore.save()
                    authManager.clearPassword()
                    authManager.disableFaceID()
                    ShieldManager.shared.clearSelection()
                    ShieldManager.shared.unlockAll()
                }
            } message: {
                Text(LocalizedStringKey("reset_confirm_message"))
            }
        }
    }

    // MARK: - 顶部图标

    private var topIconSection: some View {
        ZStack {
            Circle()
                .fill(Color.lockerBlue.opacity(0.1))
                .frame(width: 100, height: 100)
                .blur(radius: 12)

            Image(systemName: "gearshape.fill")
                .font(.system(size: 36))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.lockerBlue, .lockerBlue.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .frame(height: 100)
    }

    // MARK: - 安全设置

    private var securityCard: some View {
        VStack(spacing: 0) {
                                    sectionHeader(NSLocalizedString("settings_section_security", comment: ""))

            GlassCard(cornerRadius: 16) {
                VStack(spacing: 0) {
                    // 密码设置
                    passwordRow

                    Divider()
                        .padding(.leading, 44)

                    // Face ID
                    if authManager.isFaceIDAvailable {
                        faceIDRow
                    }
                }
                .padding(4)
            }
        }
    }

    private var passwordRow: some View {
        Button(action: { showPasswordSheet = true }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(authManager.isPasswordSet ? Color.lockerGreen : Color.lockerBlue)
                        .frame(width: 32, height: 32)
                    Image(systemName: authManager.isPasswordSet ? "checkmark" : "key.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                                        Text(LocalizedStringKey("settings_password_title"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(authManager.isPasswordSet ? LocalizedStringKey("settings_password_set") : LocalizedStringKey("settings_password_not_set"))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.vertical, 4)
    }

    private var faceIDRow: some View {
        Toggle(isOn: Binding(
            get: { authManager.isFaceIDEnabled },
            set: { newValue in
                if newValue {
                    Task { await authManager.enableFaceID() }
                } else {
                    authManager.disableFaceID()
                }
            }
        )) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.lockerOrange)
                        .frame(width: 32, height: 32)
                    Image(systemName: "faceid")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                                        Text(LocalizedStringKey("settings_faceid"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(authManager.isFaceIDEnabled ? LocalizedStringKey("settings_faceid_enabled") : LocalizedStringKey("settings_faceid_disabled"))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: .lockerGreen))
        .padding(.vertical, 4)
    }

    // MARK: - 功能设置

    private var featureCard: some View {
        VStack(spacing: 0) {
                                    sectionHeader(NSLocalizedString("settings_section_feature", comment: ""))

            GlassCard(cornerRadius: 16) {
                VStack(spacing: 0) {
                    Button(action: { tempGoalMinutes = appState.weeklyGoalMinutes; showGoalEditor = true }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.lockerBlue)
                                    .frame(width: 32, height: 32)
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                                                Text(LocalizedStringKey("settings_weekly_goal"))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text(String(format: NSLocalizedString("settings_weekly_goal_value", comment: ""), appState.weeklyGoalMinutes))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.vertical, 4)
                }
                .padding(4)
            }
        }
    }

    // MARK: - 数据管理

    private var dataCard: some View {
        VStack(spacing: 0) {
                                    sectionHeader(NSLocalizedString("settings_section_data", comment: ""))

            GlassCard(cornerRadius: 16) {
                VStack(spacing: 0) {
                    Button(action: exportCSV) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.lockerGreen)
                                    .frame(width: 32, height: 32)
                                Image(systemName: "square.and.arrow.up.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                                                Text(LocalizedStringKey("settings_export_data"))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text(LocalizedStringKey("settings_export_subtitle"))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.vertical, 4)

                    Divider()
                        .padding(.leading, 44)

                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.lockerRed)
                                    .frame(width: 32, height: 32)
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedStringKey("settings_reset_all"))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.red)
                                Text(LocalizedStringKey("settings_reset_subtitle"))
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.vertical, 4)
                }
                .padding(4)
            }
        }
    }

    // MARK: - 关于

    private var aboutCard: some View {
        VStack(spacing: 0) {
                                    sectionHeader(NSLocalizedString("settings_section_about", comment: ""))

            GlassCard(cornerRadius: 16) {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(.systemGray4))
                                .frame(width: 32, height: 32)
                            Image(systemName: "info")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(LocalizedStringKey("settings_version_label"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            Text("1.0")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .padding(4)
            }
        }
    }

    // MARK: - 辅助视图

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
    }

    // MARK: - 每周目标编辑

    private var goalEditorSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 16) {
                                        Text(LocalizedStringKey("settings_weekly_goal_editor_title"))
                        .font(.system(size: 20, weight: .bold, design: .rounded))

                    Text(LocalizedStringKey("settings_weekly_goal_desc"))
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    Picker("目标时长", selection: $tempGoalMinutes) {
                        Text("60 分钟/周").tag(60)
                        Text("120 分钟/周").tag(120)
                        Text("150 分钟/周").tag(150)
                        Text("200 分钟/周").tag(200)
                        Text("300 分钟/周").tag(300)
                        Text("420 分钟/周").tag(420)
                        Text("600 分钟/周").tag(600)
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)

                    HStack {
                        Text(LocalizedStringKey("settings_custom_label"))
                            .foregroundColor(.gray)
                        TextField("150", value: $tempGoalMinutes, formatter: NumberFormatter())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                        Text(LocalizedStringKey("settings_custom_unit"))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
            }
            .padding(32)
            .background(Color(.systemBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(LocalizedStringKey("password_cancel")) { showGoalEditor = false }
                        .foregroundColor(.gray)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(LocalizedStringKey("settings_save")) {
                        appState.weeklyGoalMinutes = max(30, min(1000, tempGoalMinutes))
                        appState.save()
                        showGoalEditor = false
                    }
                    .foregroundColor(.lockerBlue)
                }
            }
        }
    }

    // MARK: - CSV 导出

    private func exportCSV() {
        let sessions = lockStore.history.filter { $0.isCompleted }
        var csvString = "日期,开始时间,结束时间,计划分钟,实际分钟,被锁应用数,是否到期解锁\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        for session in sessions.sorted(by: { $0.startedAt > $1.startedAt }) {
            let startDate = dateFormatter.string(from: session.startedAt)
            let endDateStr = session.endedAt != nil ? dateFormatter.string(from: session.endedAt!) : ""
            let status = session.wasCompleted ? "是" : (session.wasEarlyUnlocked ? "提前解锁" : "")

            let row = "\"\(startDate)\",\"\(endDateStr)\",\(session.plannedMinutes),\(session.actualMinutes),\(session.appCount),\"\(status)\"\n"
            csvString += row
        }

        let tempDir = FileManager.default.temporaryDirectory
        let csvFile = tempDir.appendingPathComponent("应用锁_锁定记录_\(Int(Date().timeIntervalSince1970)).csv")

        do {
            try csvString.write(to: csvFile, atomically: true, encoding: .utf8)
            csvURL = csvFile
            showExportSheet = true
        } catch {
            print("Failed to write CSV: \(error)")
        }
    }
}

// MARK: - 密码设置表单

struct PasswordSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    let authManager: AuthManager

    @State private var password = ""
    @State private var confirm = ""
    @State private var showMismatch = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 28) {
                    // 图标
                    ZStack {
                        Circle()
                            .fill(Color.lockerBlue.opacity(0.12))
                            .frame(width: 88, height: 88)
                        Image(systemName: authManager.isPasswordSet ? "checkmark.shield.fill" : "key.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(authManager.isPasswordSet ? Color.lockerGreen : Color.lockerBlue)
                    }
                    .padding(.top, 24)

                    if authManager.isPasswordSet {
                        // 已设置密码 → 显示修改/删除选项
                        VStack(spacing: 12) {
                            Text(LocalizedStringKey("password_set_title"))
                                .font(.system(size: 24, weight: .bold))

                            Text(LocalizedStringKey("password_set_desc"))
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            VStack(spacing: 12) {
                                SecureField(LocalizedStringKey("password_new_placeholder"), text: $password)
                                    .font(.system(size: 17))
                                    .padding(14)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                SecureField(LocalizedStringKey("password_confirm_placeholder"), text: $confirm)
                                    .font(.system(size: 17))
                                    .padding(14)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text(LocalizedStringKey("password_delete_btn"))
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.red)
                        }
                        .buttonStyle(ScaleButtonStyle())

                        Spacer()

                        Button(action: savePassword) {
                            Text(password.isEmpty ? LocalizedStringKey("password_close") : LocalizedStringKey("password_save_changes"))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(password.isEmpty ? Color.gray : Color.lockerBlue)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(false)
                        .buttonStyle(ScaleButtonStyle())

                    } else {
                        // 未设置密码 → 显示设置表单
                        VStack(spacing: 12) {
                            Text(LocalizedStringKey("password_setup_title"))
                                .font(.system(size: 24, weight: .bold))

                            Text(LocalizedStringKey("password_setup_desc"))
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            VStack(spacing: 12) {
                                SecureField(LocalizedStringKey("password_input_placeholder"), text: $password)
                                    .font(.system(size: 17))
                                    .padding(14)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                SecureField(LocalizedStringKey("password_confirm_placeholder2"), text: $confirm)
                                    .font(.system(size: 17))
                                    .padding(14)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        if showMismatch {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(LocalizedStringKey("password_mismatch"))
                            }
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                            .transition(.opacity)
                        }

                        Spacer()

                        Button(action: savePassword) {
                            Text(LocalizedStringKey("password_save"))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(password.isEmpty ? Color.gray : Color.lockerBlue)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: password.isEmpty ? .clear : Color.lockerBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(password.isEmpty)
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
            }
            .alert(LocalizedStringKey("password_delete_confirm_title"), isPresented: $showDeleteConfirm) {
                Button(LocalizedStringKey("password_cancel"), role: .cancel) { }
                Button(LocalizedStringKey("password_delete_btn_alert"), role: .destructive) {
                    authManager.clearPassword()
                    dismiss()
                }
            } message: {
                Text(LocalizedStringKey("password_delete_confirm_msg"))
            }
            .navigationTitle(LocalizedStringKey("password_sheet_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStringKey("password_cancel")) { dismiss() }
                }
            }
        }
    }

    private func savePassword() {
        if authManager.isPasswordSet {
            // 修改密码或退出
            if password.isEmpty {
                dismiss()
                return
            }
        }

        guard password == confirm, !password.isEmpty else {
            withAnimation { showMismatch = true }
            return
        }

        authManager.setPassword(password)
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(AppState.shared)
        .environmentObject(LockStore.shared)
        .environmentObject(AuthManager.shared)
}
