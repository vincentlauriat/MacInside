import Foundation
import WidgetKit

/// Publie l'état courant de l'app vers le conteneur App Group lu par les widgets.
///
/// Deux cadences volontairement distinctes :
/// - **l'écriture du fichier** suit la boucle de rafraîchissement du dashboard
///   (sérialiser une petite struct est négligeable) ;
/// - **`reloadAllTimelines()`** est throttlé fort. WidgetKit budgète les
///   rechargements par jour : en demander à chaque tick ferait consommer le
///   quota en quelques minutes, après quoi le système cesserait d'honorer les
///   demandes — les widgets seraient *moins* à jour, pas plus.
@MainActor
final class WidgetSnapshotPublisher {
    /// Intervalle minimal entre deux demandes de rechargement. Ordre de grandeur
    /// aligné sur ce que WidgetKit accorde en pratique ; descendre plus bas ne
    /// rendrait pas les widgets plus frais.
    private static let reloadInterval: TimeInterval = 5 * 60

    private var lastReload: Date?

    func publish(from model: AppModel) {
        let snapshot = Self.snapshot(from: model)
        guard WidgetSnapshotStore.write(snapshot) else { return }

        let now = snapshot.capturedAt
        if let lastReload, now.timeIntervalSince(lastReload) < Self.reloadInterval { return }
        lastReload = now
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func snapshot(from model: AppModel) -> WidgetSnapshot {
        let cpu = model.cpu
        let memory = model.memory
        let sensors = model.sensors
        let battery = model.battery

        // Même partition que le dashboard : les capteurs « Battery » vivent dans
        // la carte Batterie, pas dans la carte Capteurs (cf. BatteryCardView /
        // TemperatureCardView).
        let batteryTemperatures = sensors.temperatures.filter { $0.label.hasPrefix("Battery") }
        let otherTemperatures = sensors.temperatures.filter { !$0.label.hasPrefix("Battery") }
        let hottest = otherTemperatures.max { $0.celsius < $1.celsius }

        return WidgetSnapshot(
            capturedAt: Date(),
            cpu: .init(
                totalPercent: cpu.totalPercent,
                userPercent: cpu.userPercent,
                systemPercent: cpu.systemPercent,
                history: Array(cpu.loadHistory.suffix(WidgetSnapshot.historyLimit)),
                topProcessName: cpu.topProcesses.first?.name,
                topProcessPercent: cpu.topProcesses.first?.value
            ),
            memory: .init(
                usedPercent: memory.usedPercent,
                usedBytes: memory.usedBytes,
                totalBytes: memory.totalBytes,
                history: Array(memory.loadHistory.suffix(WidgetSnapshot.historyLimit)),
                topProcessName: memory.topProcesses.first?.name,
                topProcessBytes: memory.topProcesses.first?.value
            ),
            // `nil` plutôt qu'une struct à zéro : le widget doit distinguer
            // « Mac sans batterie » de « batterie déchargée ».
            battery: battery.isPresent ? .init(
                percentage: battery.percentage,
                isCharging: battery.isCharging,
                healthPercent: battery.healthPercent,
                cycleCount: battery.cycleCount,
                timeRemainingMinutes: battery.timeRemainingMinutes,
                celsius: batteryTemperatures.first?.celsius
            ) : nil,
            sensors: .init(
                available: sensors.available,
                hasFans: sensors.hasFans,
                maxCelsius: hottest?.celsius,
                maxLabel: hottest?.label,
                readings: otherTemperatures
                    .sorted { $0.celsius > $1.celsius }
                    .prefix(WidgetSnapshot.sensorLimit)
                    .map { .init(label: $0.label, celsius: $0.celsius) },
                fanRPMs: sensors.fans.map(\.rpm)
            )
        )
    }
}
