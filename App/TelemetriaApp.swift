import SwiftUI
import WatchKit
import WidgetKit

@main
struct TelemetriaApp: App {
    @WKApplicationDelegateAdaptor(RefreshDelegate.self) var delegate
    var body: some Scene { WindowGroup { Dashboard() } }
}

final class RefreshDelegate: NSObject, WKApplicationDelegate {
    static func schedule() {
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: Date().addingTimeInterval(30 * 60), userInfo: nil) { _ in }
    }
    func applicationDidFinishLaunching() { Self.schedule() }
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if let refresh = task as? WKApplicationRefreshBackgroundTask {
                Task {
                    let snapshot = await HealthReader().load()
                    try? SnapshotStore.write(snapshot)
                    WidgetCenter.shared.reloadAllTimelines()
                    Self.schedule()
                    refresh.setTaskCompletedWithSnapshot(false)
                }
            } else {
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}

struct Dashboard: View {
    @Environment(\.scenePhase) private var phase
    @State private var data = SnapshotStore.read()
    @State private var demo = false
    @State private var busy = false
    @State private var errorText: String?
    private var shown: TelemetrySnapshot { demo ? .example : data }

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                Text("TELEMETRÍA / 02")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.orange)
                Text(Date(), style: .time)
                    .font(.system(size: 34, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.orange)
                if demo {
                    Text("DEMOSTRACIÓN · DATOS FICTICIOS")
                        .font(.system(size: 9, weight: .bold)).foregroundStyle(.orange)
                }
                IndustrialPanel(label: "PASOS", value: TelemetrySnapshot.number(shown.dailyValue(shown.steps)), symbol: "figure.walk")
                HStack(spacing: 5) {
                    IndustrialPanel(label: "KCAL", value: TelemetrySnapshot.number(shown.dailyValue(shown.kilocalories)), symbol: "flame", compact: true)
                    IndustrialPanel(label: "KM", value: TelemetrySnapshot.number(shown.dailyValue(shown.kilometers), decimals: 1), symbol: "location", compact: true)
                }
                IndustrialPanel(label: "ÚLTIMO PULSO", value: TelemetrySnapshot.number(shown.pulse), symbol: "heart", compact: true)
                if let pulseAt = shown.pulseAt {
                    Text("Lectura: \(pulseAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 9)).foregroundStyle(.secondary)
                }
                Text(Date(), format: .dateTime.day().month(.wide))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.orange)
                if !demo {
                    if let updated = data.updatedAt {
                        Text("Consulta: \(updated.formatted(date: .abbreviated, time: .shortened))")
                            .font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                    Text("— = sin datos accesibles. El pulso no es una medición continua.")
                        .font(.system(size: 9)).foregroundStyle(.secondary)
                }
                Button("Conectar Salud") { Task { await refresh(requestAccess: true) } }
                    .disabled(busy || demo)
                Button(busy ? "Actualizando…" : "Actualizar") { Task { await refresh(requestAccess: false) } }
                    .disabled(busy || demo)
                Toggle("Ver demostración", isOn: $demo).font(.footnote)
                if let errorText { Text(errorText).font(.footnote).foregroundStyle(.orange) }
            }
            .padding(.horizontal, 2)
        }
        .background(.black)
        .onChange(of: phase) { _, value in
            if value == .active && !demo { Task { await refresh(requestAccess: false) } }
        }
    }

    @MainActor private func refresh(requestAccess: Bool) async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        errorText = nil
        let reader = HealthReader()
        do {
            if requestAccess { try await reader.authorize() }
            let latest = await reader.load()
            try SnapshotStore.write(latest)
            data = latest
            WidgetCenter.shared.reloadAllTimelines()
            RefreshDelegate.schedule()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
