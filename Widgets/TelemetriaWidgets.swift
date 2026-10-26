import SwiftUI
import WidgetKit

struct TelemetryEntry: TimelineEntry {
    let date: Date
    let snapshot: TelemetrySnapshot
    var preview = false
}

struct TelemetryProvider: TimelineProvider {
    func placeholder(in context: Context) -> TelemetryEntry {
        TelemetryEntry(date: Date(), snapshot: .empty)
    }
    func getSnapshot(in context: Context, completion: @escaping (TelemetryEntry) -> Void) {
        completion(TelemetryEntry(date: Date(), snapshot: context.isPreview ? .example : SnapshotStore.read(),
                                  preview: context.isPreview))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<TelemetryEntry>) -> Void) {
        let now = Date()
        let data = SnapshotStore.read()
        // Additional entries hide yesterday's totals and mark stale values even without a new read.
        var dates = (0...24).map { now.addingTimeInterval(Double($0) * 3600) }
        if let midnight = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now)) {
            dates.append(midnight)
        }
        if let updated = data.updatedAt {
            let expires = updated.addingTimeInterval(3601)
            if expires > now { dates.append(expires) }
        }
        let entries = Array(Set(dates)).sorted().map {
            TelemetryEntry(date: $0, snapshot: data)
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(1800))))
    }
}

struct TelemetryWidgetView: View {
    let entry: TelemetryEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        Group {
            if family == .accessoryCircular {
                VStack(spacing: 1) {
                    Image(systemName: "figure.walk").widgetAccentable()
                    Text(TelemetrySnapshot.number(entry.snapshot.dailyValue(entry.snapshot.steps, at: entry.date)))
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .minimumScaleFactor(0.5).lineLimit(1)
                    Text(entry.preview ? "DEMO" : entry.snapshot.stale(at: entry.date) ? "ANTIGUO" : "PASOS")
                        .font(.system(size: 7))
                }
            } else {
                VStack(spacing: 2) {
                    HStack(spacing: 3) {
                        IndustrialPanel(label: "PASOS",
                            value: TelemetrySnapshot.number(entry.snapshot.dailyValue(entry.snapshot.steps, at: entry.date)),
                            symbol: "figure.walk", compact: true)
                        IndustrialPanel(label: "KCAL",
                            value: TelemetrySnapshot.number(entry.snapshot.dailyValue(entry.snapshot.kilocalories, at: entry.date)),
                            symbol: "flame", compact: true)
                        IndustrialPanel(label: "KM",
                            value: TelemetrySnapshot.number(entry.snapshot.dailyValue(entry.snapshot.kilometers, at: entry.date), decimals: 1),
                            symbol: "location", compact: true)
                    }
                    HStack {
                        Text(entry.preview ? "DEMO" : entry.snapshot.stale(at: entry.date) ? "SIN DATOS RECIENTES" : "TELEMETRÍA")
                        Spacer(minLength: 2)
                        if let date = entry.snapshot.updatedAt { Text(date, style: .time) }
                    }
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .lineLimit(1).minimumScaleFactor(0.7)
                }
            }
        }
        .privacySensitive()
        .containerBackground(for: .widget) { Color.black }
    }
}

@main
struct TelemetriaWidgets: Widget {
    let kind = "Telemetria02"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TelemetryProvider()) { entry in
            TelemetryWidgetView(entry: entry)
        }
        .configurationDisplayName("Telemetría naranja")
        .description("Panel de pasos, kcal y kilómetros. La actualización depende de watchOS.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular])
    }
}
