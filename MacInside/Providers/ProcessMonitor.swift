import Foundation
import Darwin

/// Top process par CPU et par mémoire, via `libproc` (pas besoin de sandbox
/// désactivée pour la lecture — déjà nécessaire pour `SensorMonitor`).
final class ProcessMonitor {
    private struct Sample { var totalTimeNanos: UInt64; var date: Date }
    private var previousSamples: [Int32: Sample] = [:]
    private let timebase: mach_timebase_info = {
        var info = mach_timebase_info()
        mach_timebase_info(&info)
        return info
    }()

    func topByCPU(limit: Int = 6) -> [ProcessUsageEntry] {
        var entries: [ProcessUsageEntry] = []
        let now = Date()

        for pid in listPIDs() {
            var taskInfo = proc_taskinfo()
            let size = Int32(MemoryLayout<proc_taskinfo>.size)
            let result = withUnsafeMutablePointer(to: &taskInfo) {
                proc_pidinfo(pid, PROC_PIDTASKINFO, 0, $0, size)
            }
            guard result == size else { continue }

            let totalTicks = taskInfo.pti_total_user + taskInfo.pti_total_system
            let totalNanos = totalTicks * UInt64(timebase.numer) / UInt64(max(timebase.denom, 1))

            defer { previousSamples[pid] = Sample(totalTimeNanos: totalNanos, date: now) }

            guard let previous = previousSamples[pid] else { continue }
            let elapsed = now.timeIntervalSince(previous.date)
            guard elapsed > 0, totalNanos >= previous.totalTimeNanos else { continue }

            let deltaSeconds = Double(totalNanos - previous.totalTimeNanos) / 1_000_000_000
            let percent = deltaSeconds / elapsed * 100
            // Pas de seuil minimal : un filtre par pourcentage fait varier le nombre
            // d'entrées d'un tick à l'autre (0 à N), ce qui fait "sauter" la hauteur
            // de la carte CPU. On garde toujours `limit` entrées (triées) une fois
            // que des échantillons existent, y compris à ~0%.
            guard let name = processName(pid) else { continue }
            entries.append(ProcessUsageEntry(pid: pid, name: name, value: max(percent, 0)))
        }

        return Array(entries.sorted { $0.value > $1.value }.prefix(limit))
    }

    func topByMemory(limit: Int = 6) -> [ProcessUsageEntry] {
        var entries: [ProcessUsageEntry] = []

        for pid in listPIDs() {
            var taskInfo = proc_taskinfo()
            let size = Int32(MemoryLayout<proc_taskinfo>.size)
            let result = withUnsafeMutablePointer(to: &taskInfo) {
                proc_pidinfo(pid, PROC_PIDTASKINFO, 0, $0, size)
            }
            guard result == size, taskInfo.pti_resident_size > 0, let name = processName(pid) else { continue }
            entries.append(ProcessUsageEntry(pid: pid, name: name, value: Double(taskInfo.pti_resident_size)))
        }

        return Array(entries.sorted { $0.value > $1.value }.prefix(limit))
    }

    private func listPIDs() -> [Int32] {
        let bufferSize = proc_listallpids(nil, 0)
        guard bufferSize > 0 else { return [] }
        var pids = [Int32](repeating: 0, count: Int(bufferSize) / MemoryLayout<Int32>.size)
        let written = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<Int32>.size))
        guard written > 0 else { return [] }
        return Array(pids.prefix(Int(written)))
    }

    private func processName(_ pid: Int32) -> String? {
        // PROC_PIDPATHINFO_MAXSIZE est une macro C (4 * MAXPATHLEN) non pontée vers Swift.
        var buffer = [CChar](repeating: 0, count: 4 * 1024)
        let length = proc_name(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else { return nil }
        return String(cString: buffer)
    }
}
