import WidgetKit
import SwiftUI

// MARK: - Provider

struct FocusWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusWidgetEntry {
        FocusWidgetEntry(isLocking: false, todayMinutes: 0, remainingSeconds: 0, plannedMinutes: 25)
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusWidgetEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusWidgetEntry>) -> Void) {
        let entry = loadEntry()
        // 刷新策略：如果正在锁定，每30秒刷新；否则每15分钟刷新
        let refreshInterval = entry.isLocking ? 30.0 : 900.0
        let nextUpdate = Date().addingTimeInterval(refreshInterval)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> FocusWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.com.pangtong.applocker")
        let isLocking = defaults?.bool(forKey: "isLocking") ?? false
        let todayMinutes = defaults?.integer(forKey: "todayLockMinutes") ?? 0
        let startTime = defaults?.object(forKey: "lockStartTime") as? Date ?? Date()
        let plannedMinutes = defaults?.integer(forKey: "lockPlannedMinutes") ?? 25

        let elapsed = Int(Date().timeIntervalSince(startTime))
        let total = plannedMinutes * 60
        let remaining = max(0, total - elapsed)

        return FocusWidgetEntry(
            isLocking: isLocking,
            todayMinutes: todayMinutes,
            remainingSeconds: remaining,
            plannedMinutes: plannedMinutes
        )
    }
}

// MARK: - Entry

struct FocusWidgetEntry: TimelineEntry {
    let date = Date()
    let isLocking: Bool
    let todayMinutes: Int
    let remainingSeconds: Int
    let plannedMinutes: Int

    var formattedRemaining: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Widget View

struct FocusWidgetEntryView: View {
    var entry: FocusWidgetProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    private var smallWidget: some View {
        VStack(spacing: 8) {
            Image(systemName: entry.isLocking ? "lock.shield.fill" : "lock.shield")
                .font(.system(size: 24))
                .foregroundColor(entry.isLocking ? .green : .blue)

            if entry.isLocking {
                Text(entry.formattedRemaining)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)

                Text(String(format: NSLocalizedString("widget_min_today", comment: ""), entry.todayMinutes))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
            } else {
                Text("widget_focus")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(String(format: NSLocalizedString("widget_min_today", comment: ""), entry.todayMinutes))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
        .containerBackground(.background, for: .widget)
    }

    private var mediumWidget: some View {
        HStack(spacing: 16) {
            // 左侧状态
            VStack(spacing: 6) {
                Image(systemName: entry.isLocking ? "lock.shield.fill" : "lock.shield")
                    .font(.system(size: 28))
                    .foregroundColor(entry.isLocking ? .green : .blue)

                Text(entry.isLocking ? NSLocalizedString("widget_focusing", comment: "") : NSLocalizedString("widget_idle", comment: ""))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Divider()

            // 右侧详情
            VStack(alignment: .leading, spacing: 4) {
                if entry.isLocking {
                    Text(entry.formattedRemaining)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)

                    Text(String(format: NSLocalizedString("widget_min_session", comment: ""), entry.plannedMinutes))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                    Text(String(format: NSLocalizedString("widget_min_today", comment: ""), entry.todayMinutes))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Widget

struct FocusWidget: Widget {
    let kind: String = "com.pangtong.applocker.focuswidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusWidgetProvider()) { entry in
            FocusWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("widget_config_name", comment: ""))
        .description(NSLocalizedString("widget_config_desc", comment: ""))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Bundle

@main
struct FocusWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusWidget()
    }
}
