import Foundation
import IOKit.ps
import IOKit

/// État de la batterie via `IOPowerSources` (présence/charge/temps restant)
/// et le registre IOKit `AppleSmartBattery` (cycles, santé). Renvoie
/// `isPresent = false` sur un Mac de bureau sans batterie — la carte
/// correspondante doit alors être masquée.
final class BatteryMonitor {
    func snapshot() -> BatteryStats {
        var stats = BatteryStats()

        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let first = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, first)?.takeUnretainedValue() as? [String: Any]
        else { return stats }

        stats.isPresent = true
        let current = description[kIOPSCurrentCapacityKey] as? Int ?? 0
        let max = description[kIOPSMaxCapacityKey] as? Int ?? 100
        stats.percentage = max > 0 ? Int(Double(current) / Double(max) * 100) : 0
        stats.isCharging = (description[kIOPSIsChargingKey] as? Bool) ?? false

        // `kIOPSTimeToEmptyKey`/`kIOPSTimeToFullChargeKey` (dictionnaire de
        // description) ne sont plus fiablement peuplées sur Apple Silicon —
        // elles restent bloquées à -1 en continu. `IOPSGetTimeRemainingEstimate()`
        // est l'API recommandée par Apple depuis macOS 10.15 pour cette valeur,
        // que la batterie soit en charge ou en décharge.
        let estimate = IOPSGetTimeRemainingEstimate()
        stats.timeRemainingMinutes = estimate > 0 ? Int(estimate / 60) : nil

        stats.wattage = Self.adapterWattage()
        (stats.cycleCount, stats.healthPercent) = Self.registryStats()

        return stats
    }

    private static func adapterWattage() -> Double {
        guard let details = IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() as? [String: Any],
              let watts = details[kIOPSPowerAdapterWattsKey] as? Double else { return 0 }
        return watts
    }

    private static func registryStats() -> (cycleCount: Int, healthPercent: Int) {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return (0, 100) }
        defer { IOObjectRelease(service) }

        let cycles = intProperty(service, "CycleCount") ?? 0
        let designCapacity = intProperty(service, "DesignCapacity") ?? 0
        let maxCapacity = intProperty(service, "AppleRawMaxCapacity") ?? intProperty(service, "MaxCapacity") ?? 0
        let health = designCapacity > 0 ? Int(Double(maxCapacity) / Double(designCapacity) * 100) : 100
        return (cycles, min(health, 100))
    }

    private static func intProperty(_ service: io_service_t, _ key: String) -> Int? {
        IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue() as? Int
    }
}
