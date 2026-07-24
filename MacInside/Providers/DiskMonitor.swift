import Foundation
import IOKit

/// Volume système et volumes externes montés, via l'API `URLResourceValues`,
/// + débit lecture/écriture agrégé (tous disques confondus) via le dictionnaire
/// `Statistics` exposé par les services IOKit `IOBlockStorageDriver` — même
/// technique que `GPUMonitor` pour `IOAccelerator`. Agrégé plutôt que par
/// volume : ces compteurs vivent sur le pilote physique, pas sur les volumes/
/// conteneurs APFS montés (plusieurs volumes peuvent partager un même disque).
final class DiskMonitor {
    private var previousSample: (bytesRead: UInt64, bytesWritten: UInt64, date: Date)?
    private var readHistory: [Double] = []
    private var writeHistory: [Double] = []
    private let historyLimit = 60
    private var totalReadBytes: UInt64 = 0
    private var totalWriteBytes: UInt64 = 0

    func snapshot() -> DiskStats {
        var stats = DiskStats()
        stats.systemVolume = volumeStats(for: URL(fileURLWithPath: "/"), isExternal: false)
        stats.externalVolumes = externalVolumes()

        let (bytesRead, bytesWritten) = Self.aggregateStatistics()
        let now = Date()
        if let previous = previousSample {
            let elapsed = now.timeIntervalSince(previous.date)
            if elapsed > 0 {
                // Compteurs cumulés depuis le boot : peuvent diminuer d'un tick
                // à l'autre si un disque externe est débranché entre deux
                // lectures. Une soustraction wrapping (&-) produirait alors une
                // valeur proche de UInt64.max (cf. bug déjà corrigé sur le
                // réseau, voir CHANGES.md).
                let deltaRead = bytesRead >= previous.bytesRead ? bytesRead - previous.bytesRead : 0
                let deltaWrite = bytesWritten >= previous.bytesWritten ? bytesWritten - previous.bytesWritten : 0
                stats.readBytesPerSec = Double(deltaRead) / elapsed
                stats.writeBytesPerSec = Double(deltaWrite) / elapsed
                totalReadBytes += deltaRead
                totalWriteBytes += deltaWrite
            }
        }
        previousSample = (bytesRead, bytesWritten, now)
        stats.totalReadBytes = totalReadBytes
        stats.totalWriteBytes = totalWriteBytes

        readHistory.append(stats.readBytesPerSec)
        writeHistory.append(stats.writeBytesPerSec)
        if readHistory.count > historyLimit { readHistory.removeFirst(readHistory.count - historyLimit) }
        if writeHistory.count > historyLimit { writeHistory.removeFirst(writeHistory.count - historyLimit) }
        stats.readHistory = readHistory
        stats.writeHistory = writeHistory

        return stats
    }

    /// Somme des compteurs cumulés "Bytes (Read)"/"Bytes (Write)" de tous les
    /// pilotes de stockage bloc actifs (un par disque physique).
    private static func aggregateStatistics() -> (read: UInt64, written: UInt64) {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOBlockStorageDriver"), &iterator) == KERN_SUCCESS
        else { return (0, 0) }
        defer { IOObjectRelease(iterator) }

        var totalRead: UInt64 = 0
        var totalWritten: UInt64 = 0
        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            guard let statistics = IORegistryEntryCreateCFProperty(
                service, "Statistics" as CFString, kCFAllocatorDefault, 0
            )?.takeRetainedValue() as? [String: Any] else { continue }

            totalRead += (statistics["Bytes (Read)"] as? Int).map { UInt64($0) } ?? 0
            totalWritten += (statistics["Bytes (Write)"] as? Int).map { UInt64($0) } ?? 0
        }
        return (totalRead, totalWritten)
    }

    private func volumeStats(for url: URL, isExternal: Bool, nameOverride: String? = nil) -> VolumeStats? {
        guard let values = try? url.resourceValues(forKeys: [
            .volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey
        ]) else { return nil }

        let total = values.volumeTotalCapacity.map { UInt64($0) } ?? 0
        let available = values.volumeAvailableCapacityForImportantUsage.map { UInt64($0) } ?? 0

        return VolumeStats(
            name: nameOverride ?? values.volumeName ?? url.lastPathComponent,
            totalBytes: total,
            availableBytes: available,
            isExternal: isExternal
        )
    }

    private func externalVolumes() -> [VolumeStats] {
        let keys: [URLResourceKey] = [
            .volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey,
            .volumeIsInternalKey, .volumeIsBrowsableKey
        ]
        guard let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) else { return [] }

        return urls.compactMap { url -> VolumeStats? in
            guard let values = try? url.resourceValues(forKeys: Set(keys)) else { return nil }
            guard values.volumeIsInternal == false else { return nil }
            return volumeStats(for: url, isExternal: true, nameOverride: values.volumeName)
        }
    }
}
