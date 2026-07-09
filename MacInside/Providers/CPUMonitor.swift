import Foundation
import Darwin

/// Charge CPU globale et par cœur, via `host_processor_info` (deltas entre deux
/// échantillons — l'API ne fournit que des compteurs de ticks cumulés).
final class CPUMonitor {
    private var previousTicksByCore: [[UInt32]] = []
    private var history: [Double] = []
    private let historyLimit = 60

    func snapshot() -> CPUStats {
        var stats = CPUStats()

        var cpuCount: natural_t = 0
        var infoArray: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &cpuCount,
            &infoArray,
            &infoCount
        )

        guard result == KERN_SUCCESS, let infoArray else { return stats }
        defer {
            let size = vm_size_t(Int(infoCount) * MemoryLayout<Int32>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: infoArray), size)
        }

        let cpuLoadInfo = infoArray.withMemoryRebound(to: Int32.self, capacity: Int(infoCount)) { $0 }

        var currentTicksByCore: [[UInt32]] = []
        var totalUser: Double = 0, totalSystem: Double = 0, totalIdle: Double = 0, totalNice: Double = 0
        var perCoreLoad: [Double] = []

        for core in 0..<Int(cpuCount) {
            let base = core * Int(CPU_STATE_MAX)
            let user = UInt32(bitPattern: cpuLoadInfo[base + Int(CPU_STATE_USER)])
            let system = UInt32(bitPattern: cpuLoadInfo[base + Int(CPU_STATE_SYSTEM)])
            let idle = UInt32(bitPattern: cpuLoadInfo[base + Int(CPU_STATE_IDLE)])
            let nice = UInt32(bitPattern: cpuLoadInfo[base + Int(CPU_STATE_NICE)])
            let ticks: [UInt32] = [user, system, idle, nice]
            currentTicksByCore.append(ticks)

            if previousTicksByCore.count == Int(cpuCount) {
                let previous = previousTicksByCore[core]
                let dUser = Double(ticks[0] &- previous[0])
                let dSystem = Double(ticks[1] &- previous[1])
                let dIdle = Double(ticks[2] &- previous[2])
                let dNice = Double(ticks[3] &- previous[3])
                let dTotal = dUser + dSystem + dIdle + dNice
                let load = dTotal > 0 ? (dUser + dSystem + dNice) / dTotal * 100 : 0
                perCoreLoad.append(load)
                totalUser += dUser; totalSystem += dSystem; totalIdle += dIdle; totalNice += dNice
            }
        }

        previousTicksByCore = currentTicksByCore

        let grandTotal = totalUser + totalSystem + totalIdle + totalNice
        if grandTotal > 0 {
            stats.userPercent = (totalUser + totalNice) / grandTotal * 100
            stats.systemPercent = totalSystem / grandTotal * 100
            stats.idlePercent = totalIdle / grandTotal * 100
        }
        stats.perCoreLoad = perCoreLoad

        history.append(stats.totalPercent)
        if history.count > historyLimit { history.removeFirst(history.count - historyLimit) }
        stats.loadHistory = history

        return stats
    }
}
