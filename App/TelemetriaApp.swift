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
    @State private var demo = ProcessInfo.processInfo.arguments.contains("--demo")
    @State private var busy = false
    @State private var errorText: String?
    private var shown: TelemetrySnapshot { demo ? .example : data }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 12) {
                    TelemetryFace(snapshot: shown, demo: demo)
                        .frame(height: geometry.size.height)
                    VStack(spacing: 8) {
                        if let pulseAt = shown.pulseAt {
                            Text("Pulso: \(pulseAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                        if !demo {
                            if let updated = data.updatedAt {
                                Text("Consulta: \(updated.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.system(size: 10)).foregroundStyle(.secondary)
                            }
                            Text("— = sin datos accesibles. El pulso no es una medición continua.")
                                .font(.system(size: 10)).foregroundStyle(.secondary)
                        }
                        Button("Conectar Salud") { Task { await refresh(requestAccess: true) } }
                            .disabled(busy || demo)
                        Button(busy ? "Actualizando…" : "Actualizar") { Task { await refresh(requestAccess: false) } }
                            .disabled(busy || demo)
                        Toggle("Ver demostración", isOn: $demo).font(.footnote)
                        if let errorText { Text(errorText).font(.footnote).foregroundStyle(.orange) }
                    }
                }
            }
            .background(.black)
        }
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
