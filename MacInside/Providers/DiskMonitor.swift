import Foundation

/// Volume système et volumes externes montés, via l'API `URLResourceValues`.
final class DiskMonitor {
    func snapshot() -> DiskStats {
        var stats = DiskStats()
        stats.systemVolume = volumeStats(for: URL(fileURLWithPath: "/"), isExternal: false)
        stats.externalVolumes = externalVolumes()
        return stats
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
