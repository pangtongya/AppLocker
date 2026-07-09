// StatsView.swift
// 锁定统计数据界面

import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var lockStore: LockStore

    @State private var selectedPeriod: Period = .week
    @State private var showExportSheet = false
    @State private var csvURL: URL?

    enum Period: String, CaseIterable {
        case today = "stats_period_today"
        case week = "stats_period_week"
        case month = "stats_period_month"
        case all = "stats_period_all"
        
        var displayTitle: String {
            NSLocalizedString(rawValue, comment: "")
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                if lockStore.history.isEmpty {
                    // 空状态
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            totalTimeCard

                            Picker(LocalizedStringKey("stats_period"), selection: $selectedPeriod) {
                                ForEach(Period.allCases, id: \.self) { period in
                                    Text(period.displayTitle).tag(period)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 20)

                            dailyChart

                            detailStats

                            exportButton

                            Spacer(minLength: 100)
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("stats_title"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showExportSheet) {
                if let url = csvURL {
                    ActivityView(activityItems: [url])
                }
            }
        }
    }

    // MARK: - 空状态

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.lockerBlue.opacity(0.08))
                    .frame(width: 100, height: 100)
                    .blur(radius: 12)

                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 36))
                    .foregroundColor(.lockerBlue.opacity(0.6))
            }

            VStack(spacing: 8) {
                Text(LocalizedStringKey("stats_empty_title"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(LocalizedStringKey("stats_empty_desc"))
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - 总时长卡片

    private var totalTimeCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("stats_total_time")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(String(format: NSLocalizedString("stats_unit_minutes", comment: ""), lockStore.allTimeTotalMinutes))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(String(format: NSLocalizedString("stats_total_hours", comment: ""), lockStore.allTimeTotalMinutes / 60))
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.lockerBlue.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.lockerBlue)
                }
            }

            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("\(lockStore.currentStreak)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.lockerGreen)
                    Text("stats_current_streak")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 40)

                VStack(spacing: 4) {
                    Text("\(lockStore.longestStreak)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.lockerOrange)
                    Text("stats_longest_streak")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 40)

                VStack(spacing: 4) {
                    Text("\(lockStore.allTimeTotalSessions)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.lockerBlue)
                    Text("stats_total_sessions")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
    }

    // MARK: - 每日图表

    private var dailyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("stats_daily_lock")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                                Text(String(format: NSLocalizedString("stats_goal_format", comment: ""), Double(appState.weeklyGoalMinutes) / 7.0))
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }

            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(dailyData) { item in
                        BarMark(
                            x: .value(NSLocalizedString("chart_axis_date", comment: ""), item.date, unit: .day),
                            y: .value(NSLocalizedString("chart_axis_minutes", comment: ""), item.minutes)
                        )
                        .foregroundStyle(Color.lockerBlue.gradient)
                        .cornerRadius(4)
                    }

                    // 目标线
                    RuleMark(y: .value(NSLocalizedString("chart_axis_goal", comment: ""), Double(appState.weeklyGoalMinutes) / 7.0))
                        .foregroundStyle(Color.lockerGreen.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                        .annotation(position: .trailing) {
                            Text("\(appState.weeklyGoalMinutes / 7)")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.lockerGreen)
                        }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(dayLabel(for: date))
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
            } else {
                Text("stats_chart_needs_ios16")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding(20)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
    }

    // MARK: - 详细统计

    private var detailStats: some View {
        VStack(spacing: 16) {
            statRow(titleKey: "stats_week_sessions", value: String(format: NSLocalizedString("stats_unit_sessions", comment: ""), weekSessionsCount))
            statRow(titleKey: "stats_week_total", value: String(format: NSLocalizedString("stats_unit_minutes", comment: ""), weekTotalMinutes))
            statRow(titleKey: "stats_avg_per_session", value: averageMinutesText)
            statRow(titleKey: "stats_longest_session", value: longestSessionText)
            statRow(titleKey: "stats_avg_daily", value: averageDailyMinutesText)
            statRow(titleKey: "stats_max_streak", value: String(format: NSLocalizedString("stats_unit_days", comment: ""), lockStore.longestStreak))
            statRow(titleKey: "stats_total_count", value: String(format: NSLocalizedString("stats_unit_sessions", comment: ""), lockStore.allTimeTotalSessions))
            statRow(titleKey: "stats_completion_rate", value: completionRateText)
        }
        .padding(20)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func statRow(titleKey: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(titleKey)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
    }

    // MARK: - 导出按钮

    private var exportButton: some View {
        Button(action: exportCSV) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .medium))
                Text("stats_export")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .foregroundColor(.lockerBlue)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.lockerBlue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 计算属性

    private var weekSessionsCount: Int {
        lockStore.weekSessions.count
    }

    private var weekTotalMinutes: Int {
        lockStore.weekSessions.reduce(0) { $0 + $1.actualMinutes }
    }

    private var filteredSessions: [LockSession] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedPeriod {
        case .today:
            let todayStart = calendar.startOfDay(for: now)
            let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart)!
            return lockStore.history.filter { $0.startedAt >= todayStart && $0.startedAt < tomorrowStart && $0.isCompleted }
        case .week:
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
                return []
            }
            return lockStore.history.filter { $0.startedAt >= weekStart && $0.isCompleted }
        case .month:
            let components = calendar.dateComponents([.year, .month], from: now)
            guard let monthStart = calendar.date(from: components) else { return [] }
            return lockStore.history.filter { $0.startedAt >= monthStart && $0.isCompleted }
        case .all:
            return lockStore.history.filter { $0.isCompleted }
        }
    }

    private var averageMinutesText: String {
        let sessions = filteredSessions
        guard !sessions.isEmpty else { return String(format: NSLocalizedString("stats_unit_minutes", comment: ""), 0) }
        let avg = sessions.reduce(0) { $0 + $1.actualMinutes } / sessions.count
        return String(format: NSLocalizedString("stats_unit_minutes", comment: ""), avg)
    }

    private var longestSessionText: String {
        let sessions = filteredSessions
        guard let longest = sessions.max(by: { $0.actualMinutes < $1.actualMinutes }) else {
            return String(format: NSLocalizedString("stats_unit_minutes", comment: ""), 0)
        }
        return String(format: NSLocalizedString("stats_unit_minutes", comment: ""), longest.actualMinutes)
    }

    private var averageDailyMinutesText: String {
        let sessions = filteredSessions
        guard !sessions.isEmpty else { return String(format: NSLocalizedString("stats_unit_min_per_day", comment: ""), 0) }
        let calendar = Calendar.current
        let uniqueDays = Set(sessions.map { calendar.startOfDay(for: $0.startedAt) }).count
        guard uniqueDays > 0 else { return String(format: NSLocalizedString("stats_unit_min_per_day", comment: ""), 0) }
        let totalMinutes = sessions.reduce(0) { $0 + $1.actualMinutes }
                return String(format: NSLocalizedString("stats_unit_min_per_day", comment: ""), totalMinutes / uniqueDays)
    }

    private var completionRateText: String {
        let allSessions = lockStore.history
        guard !allSessions.isEmpty else { return "0%" }
        let completed = allSessions.filter { $0.isCompleted }.count
        let rate = Double(completed) / Double(allSessions.count) * 100
        return "\(Int(rate))%"
    }

    // MARK: - 图表数据

    private var dailyData: [DailyData] {
        let calendar = Calendar.current
        let sessions = filteredSessions
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startedAt)
        }

        return grouped.map { (date, sessions) in
            DailyData(date: date, minutes: sessions.reduce(0) { $0 + $1.actualMinutes })
        }
        .sorted { $0.date < $1.date }
    }

    private func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let daysAgo = calendar.dateComponents([.day], from: date, to: now).day ?? 0

        if daysAgo == 0 { return NSLocalizedString("date_today", comment: "") }
        if daysAgo == 1 { return NSLocalizedString("date_yesterday", comment: "") }

        // 使用 DateFormatter 获取本地化的星期缩写
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: date)
    }

    // MARK: - CSV 导出

    private func exportCSV() {
        let sessions = lockStore.history.filter { $0.isCompleted }
        guard let csvURL = CSVExporter.writeCSVToTempFile(sessions: sessions, fileName: NSLocalizedString("csv_file_name", comment: "")) else {
            return
        }
        self.csvURL = csvURL
        showExportSheet = true
    }
}

#Preview {
    StatsView()
        .environmentObject(AppState.shared)
        .environmentObject(LockStore.shared)
}
