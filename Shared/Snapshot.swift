import Foundation

struct TelemetrySnapshot: Codable {
    var updatedAt: Date?
    var steps: Double?
    var kilometers: Double?
    var kilocalories: Double?
    var pulse: Double?
    var pulseAt: Date?
    static let empty = TelemetrySnapshot()
    static let example = TelemetrySnapshot(updatedAt: Date(), steps: 6240,
        kilometers: 4.2, kilocalories: 348, pulse: 72, pulseAt: Date())

    func dailyValue(_ value: Double?, at date: Date = Date()) -> Double? {
        guard let updatedAt, Calendar.current.isDate(updatedAt, inSameDayAs: date) else { return nil }
        return value
    }
    func stale(at date: Date = Date()) -> Bool {
        guard let updatedAt else { return true }
        return date.timeIntervalSince(updatedAt) > 3600
    }
    static func number(_ value: Double?, decimals: Int = 0) -> String {
        guard let value, value.isFinite else { return "—" }
        return value.formatted(.number.precision(.fractionLength(decimals)))
    }
}

enum SnapshotStore {
    // Health values stay in the local shared container; no network or analytics.
    static var file: URL? {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "TelemetriaGroup") as? String,
              let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)
        else { return nil }
        return root.appendingPathComponent("telemetry.json")
    }
    static func read() -> TelemetrySnapshot {
        guard let file, let data = try? Data(contentsOf: file),
              let value = try? JSONDecoder().decode(TelemetrySnapshot.self, from: data)
        else { return .empty }
        return value
    }
    static func write(_ snapshot: TelemetrySnapshot) throws {
        guard let file else {
            throw NSError(domain: "Telemetria02", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "El contenedor compartido no está disponible."])
        }
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: file, options: [.atomic, .completeFileProtection])
    }
}
