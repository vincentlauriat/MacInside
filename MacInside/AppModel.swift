import Foundation
import Observation

/// Point central : agrège tous les providers sur une seule boucle de
/// rafraîchissement et publie leurs snapshots pour les vues SwiftUI.
@Observable
@MainActor
final class AppModel {
    private(set) var identity = SystemIdentity()
    private(set) var cpu = CPUStats()
    private(set) var memory = MemoryStats()
    private(set) var disk = DiskStats()
    private(set) var network = NetworkStats()
    private(set) var sensors = SensorStats()
    private(set) var battery = BatteryStats()

    private let identityProvider = SystemIdentityProvider()
    private let cpuMonitor = CPUMonitor()
    private let memoryMonitor = MemoryMonitor()
    private let diskMonitor = DiskMonitor()
    private let networkMonitor = NetworkMonitor()
    private let sensorMonitor = SensorMonitor()
    private let batteryMonitor = BatteryMonitor()
    private let processMonitor = ProcessMonitor()
    private let publicAddressLookup = PublicAddressLookup()

    private var refreshTask: Task<Void, Never>?
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    func start() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                self.refresh()
                let interval = self.settings.refreshInterval
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func refresh() {
        identity = identityProvider.snapshot()

        var cpuStats = cpuMonitor.snapshot()
        cpuStats.topProcesses = processMonitor.topByCPU()
        cpu = cpuStats

        var memoryStats = memoryMonitor.snapshot()
        memoryStats.topProcesses = processMonitor.topByMemory()
        memory = memoryStats

        disk = diskMonitor.snapshot()
        network = networkMonitor.snapshot()
        sensors = sensorMonitor.snapshot()
        battery = batteryMonitor.snapshot()

        Task { [weak self] in
            guard let self, let result = await self.publicAddressLookup.current() else { return }
            self.network.publicAddress = result.ip
            self.network.countryCode = result.countryCode
        }
    }
}
