import Foundation
import Darwin

/// Usage mémoire global via `vm_statistics64` (wired/active/compressed/libre).
final class MemoryMonitor {
    private var history: [Double] = []
    private let historyLimit = 60
    private let totalBytes: UInt64 = {
        var size: UInt64 = 0
        var len = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &size, &len, nil, 0)
        return size
    }()

    func snapshot() -> MemoryStats {
        var stats = MemoryStats()
        stats.totalBytes = totalBytes

        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)

        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return stats }

        let wired = UInt64(vmStats.wire_count) * UInt64(pageSize)
        let active = UInt64(vmStats.active_count) * UInt64(pageSize)
        let compressed = UInt64(vmStats.compressor_page_count) * UInt64(pageSize)
        let free = UInt64(vmStats.free_count) * UInt64(pageSize)
        let inactive = UInt64(vmStats.inactive_count) * UInt64(pageSize)
        let purgeable = UInt64(vmStats.purgeable_count) * UInt64(pageSize)

        stats.wiredBytes = wired
        stats.activeBytes = active
        stats.compressedBytes = compressed
        stats.availableBytes = free + inactive + purgeable

        history.append(stats.usedPercent)
        if history.count > historyLimit { history.removeFirst(history.count - historyLimit) }
        stats.loadHistory = history

        return stats
    }
}
