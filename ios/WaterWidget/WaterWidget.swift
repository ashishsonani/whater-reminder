import WidgetKit
import SwiftUI

private let appGroupId = "group.com.sarang.waterreminder"

struct WaterEntry: TimelineEntry {
    let date: Date
    let amountText: String
    let progress: Int
}

struct WaterProvider: TimelineProvider {
    func placeholder(in context: Context) -> WaterEntry {
        WaterEntry(date: Date(), amountText: "1200 / 2000 ml", progress: 60)
    }

    func getSnapshot(in context: Context, completion: @escaping (WaterEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterEntry>) -> Void) {
        // Data is pushed from the app via home_widget, which reloads this
        // timeline explicitly — no periodic refresh needed.
        completion(Timeline(entries: [loadEntry()], policy: .never))
    }

    private func loadEntry() -> WaterEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let amount = defaults?.string(forKey: "amount_text") ?? "0 / 0 ml"
        let pct = defaults?.integer(forKey: "progress_pct") ?? 0
        return WaterEntry(date: Date(), amountText: amount, progress: min(max(pct, 0), 100))
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
        }
        .padding(14)
        .widgetBackgroundCompat()
    }
}

extension View {
    /// iOS 17 requires containerBackground for widgets; older versions
    /// fall back to a plain background.
    @ViewBuilder
    func widgetBackgroundCompat() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
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
        .description("Track today's hydration at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
