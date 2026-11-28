import AppIntents
import WidgetKit
import SwiftUI

private let appGroupId = "group.com.sarang.waterreminder"

private struct LogEvent: Codable {
    let at: Int64
    let undo: Int64?
}

private struct ProgressSnapshot: Decodable {
    let current: Int
    let goal: Int
    let isMl: Bool
    let dayStart: Int64
    let ack: Int64
    let ready: Bool

    static func load(_ defaults: UserDefaults?) -> ProgressSnapshot? {
        guard let raw = defaults?.string(forKey: "quick_log_snapshot"), let data = raw.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(ProgressSnapshot.self, from: data)
    }

    static func pending(_ defaults: UserDefaults?, since ack: Int64) -> [LogEvent] {
        guard let raw = defaults?.string(forKey: "quick_log_queue"), let data = raw.data(using: .utf8),
              let values = try? JSONDecoder().decode([LogEvent].self, from: data) else {
            return []
        }
        return values.filter { $0.at > ack }
    }
}

@available(iOS 17.0, *)
private actor QuickLogQueue {
    static let shared = QuickLogQueue()

    func append(undo: Bool = false) throws {
        let defaults = UserDefaults(suiteName: appGroupId)
        guard let defaults, let snapshot = ProgressSnapshot.load(defaults), snapshot.ready else { return }
        var queue = ProgressSnapshot.pending(defaults, since: snapshot.ack)
        let latest = queue.last
        if undo {
            guard let latest, latest.undo == nil else { return }
        } else if queue.count >= 1000 {
            return
        }
        let now = Int64(Date().timeIntervalSince1970 * 1_000_000)
        let stamp = max(now, max(latest?.at ?? 0, snapshot.ack) + 1)
        queue.append(LogEvent(at: stamp, undo: undo ? latest?.at : nil))
        let data = try JSONEncoder().encode(queue)
        defaults.set(String(decoding: data, as: UTF8.self), forKey: "quick_log_queue")
    }
}

@available(iOS 17.0, *)
struct QuickLogWaterIntent: AppIntent {
    static let title: LocalizedStringResource = "Log a glass of water"
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        try await QuickLogQueue.shared.append()
        return .result()
    }
}

@available(iOS 17.0, *)
struct UndoQuickLogIntent: AppIntent {
    static let title: LocalizedStringResource = "Undo quick water log"
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        try await QuickLogQueue.shared.append(undo: true)
        return .result()
    }
}

struct WaterEntry: TimelineEntry {
    let date: Date
    let amountText: String
    let progress: Int
    let quickLogLabel: String?
    let canUndo: Bool
}

struct WaterProvider: TimelineProvider {
    func placeholder(in context: Context) -> WaterEntry {
        WaterEntry(date: Date(), amountText: "1200 / 2000 ml", progress: 60, quickLogLabel: "+250 ml", canUndo: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (WaterEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterEntry>) -> Void) {
        let start = Calendar.current.startOfDay(for: Date())
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? Date()
        completion(Timeline(entries: [loadEntry()], policy: .after(nextDay)))
    }

    private func loadEntry() -> WaterEntry {
        let now = Date()
        let defaults = UserDefaults(suiteName: appGroupId)
        guard let snapshot = ProgressSnapshot.load(defaults) else {
            return WaterEntry(date: now, amountText: "0 / 0 ml", progress: 0, quickLogLabel: nil, canUndo: false)
        }

        let calendar = Calendar.current
        let start = Int64(calendar.startOfDay(for: now).timeIntervalSince1970 * 1000)
        let pending = ProgressSnapshot.pending(defaults, since: snapshot.ack)
        let unsynced = pending.reduce(0) { sum, event in
            let date = Date(timeIntervalSince1970: Double(event.undo ?? event.at) / 1_000_000)
            guard calendar.isDate(date, inSameDayAs: now) else { return sum }
            return sum + (event.undo == nil ? 1 : -1)
        }
        let increment = snapshot.isMl ? 250 : 8
        let unit = snapshot.isMl ? "ml" : "oz"
        let current = max(0, unsynced * increment + (start == snapshot.dayStart ? snapshot.current : 0))
        let percent = snapshot.goal > 0 ? Int((100.0 * Double(current) / Double(snapshot.goal)).rounded()) : 0
        return WaterEntry(
            date: now,
            amountText: "\(current) / \(snapshot.goal) \(unit)",
            progress: min(max(percent, 0), 100),
            quickLogLabel: snapshot.ready ? "+\(increment) \(unit)" : nil,
            canUndo: pending.last.map { $0.undo == nil } ?? false
        )
    }
}

struct WaterWidgetEntryView: View {
    var entry: WaterEntry

    private let teal = Color(red: 14 / 255, green: 165 / 255, blue: 233 / 255)
    private let ink = Color(red: 15 / 255, green: 23 / 255, blue: 42 / 255)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("WATER REMINDER")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(1.2)
                    .foregroundColor(teal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Text("\(entry.progress)%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(ink)
            }
            Spacer(minLength: 0)
            Text(entry.amountText)
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            ProgressView(value: Double(entry.progress), total: 100)
                .progressViewStyle(.linear)
                .tint(teal)
            if #available(iOS 17.0, *), let label = entry.quickLogLabel {
                HStack(spacing: 4) {
                    Button(intent: QuickLogWaterIntent()) {
                        Text(label).font(.system(size: 12, weight: .semibold))
                    }
                    if entry.canUndo {
                        Button(intent: UndoQuickLogIntent()) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .accessibilityLabel("Undo")
                    }
                }
                .buttonStyle(.bordered)
                .tint(teal)
            }
        }
        .padding(14)
        .widgetBackgroundCompat()
    }
}

extension View {
    @ViewBuilder
    func widgetBackgroundCompat() -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) { Color(UIColor.systemBackground) }
        } else {
            background(Color(UIColor.systemBackground))
        }
    }
}

@main
struct WaterWidget: Widget {
    let kind: String = "WaterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WaterProvider()) { entry in
            WaterWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Water Reminder")
        .description("Track today's hydration and log a glass.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
