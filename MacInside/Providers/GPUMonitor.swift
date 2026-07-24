import Foundation
import IOKit

/// Utilisation GPU via le dictionnaire `PerformanceStatistics` exposé par le
/// service IOKit `IOAccelerator` (technique standard reprise par les outils
/// de monitoring open-source — AGXAccelerator sur Apple Silicon, pilotes
/// Intel/AMD sur les Mac Intel). Dégrade proprement si absent.
final class GPUMonitor {
    private var history: [Double] = []
    private let historyLimit = 60

    func snapshot() -> GPUStats {
        var stats = GPUStats()

        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &iterator) == KERN_SUCCESS
        else { return stats }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            guard let perf = IORegistryEntryCreateCFProperty(
                service, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0
            )?.takeRetainedValue() as? [String: Any] else { continue }

            stats.available = true
            stats.deviceUtilizationPercent = perf["Device Utilization %"] as? Int ?? 0
            stats.rendererUtilizationPercent = perf["Renderer Utilization %"] as? Int ?? 0
            stats.tilerUtilizationPercent = perf["Tiler Utilization %"] as? Int ?? 0
            stats.inUseSystemMemoryBytes = (perf["In use system memory"] as? Int).map { UInt64($0) } ?? 0
            stats.allocSystemMemoryBytes = (perf["Alloc system memory"] as? Int).map { UInt64($0) } ?? 0
            stats.recoveryCount = perf["recoveryCount"] as? Int ?? 0
            break // premier accélérateur actif suffit (un seul GPU sur la quasi-totalité des Mac)
        }

        if stats.available {
            history.append(Double(stats.deviceUtilizationPercent))
            if history.count > historyLimit { history.removeFirst(history.count - historyLimit) }
            stats.loadHistory = history
        }

        return stats
    }
}
