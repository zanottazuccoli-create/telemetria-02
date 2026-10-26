import Foundation
import HealthKit

final class HealthReader {
    private let store = HKHealthStore()
    private let identifiers: [HKQuantityTypeIdentifier] = [
        .stepCount, .distanceWalkingRunning, .activeEnergyBurned, .heartRate
    ]

    func authorize() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "Telemetria02", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Salud no está disponible en este dispositivo."])
        }
        let types = Set(identifiers.compactMap { HKObjectType.quantityType(forIdentifier: $0) })
        try await store.requestAuthorization(toShare: [], read: Set<HKObjectType>(types))
        // Completion is not evidence that read permissions were granted.
    }

    func load() async -> TelemetrySnapshot {
        guard HKHealthStore.isHealthDataAvailable() else { return .empty }
        let now = Date()
        let start = Calendar.current.startOfDay(for: now)
        async let steps = sum(.stepCount, unit: .count(), start: start, end: now)
        async let distance = sum(.distanceWalkingRunning, unit: .meterUnit(with: .kilo), start: start, end: now)
        async let energy = sum(.activeEnergyBurned, unit: .kilocalorie(), start: start, end: now)
        async let pulse = lastPulse(before: now)
        let (s, d, e, p) = await (steps, distance, energy, pulse)
        return TelemetrySnapshot(updatedAt: now, steps: s, kilometers: d,
                                 kilocalories: e, pulse: p?.0, pulseAt: p?.1)
    }

    private func sum(_ id: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: id) else { return nil }
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, result, error in
                continuation.resume(returning: error == nil ? result?.sumQuantity()?.doubleValue(for: unit) : nil)
            }
            store.execute(query)
        }
    }

    private func lastPulse(before now: Date) async -> (Double, Date)? {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else { return nil }
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: now.addingTimeInterval(-86400), end: now)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) {
                    _, samples, error in
                    guard error == nil, let sample = samples?.first as? HKQuantitySample else {
                        continuation.resume(returning: nil)
                        return
                    }
                    let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    continuation.resume(returning: (bpm, sample.endDate))
                }
            store.execute(query)
        }
    }
}
