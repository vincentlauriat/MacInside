import SwiftUI

/// Carte batterie : pourcentage, état de charge, temps restant, cycles, santé.
/// Masquée si absente (Mac de bureau).
struct BatteryCardView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let battery = model.battery
        // Température et puissance batterie : déjà lues par SensorMonitor
        // (clés SMC TB0T/Ts0P/Ts1P et PPBR), affichées ici plutôt que dans
        // Capteurs/Alimentation pour éviter la duplication (cf. TemperatureCardView/PowerCardView).
        let temperatures = model.sensors.temperatures.filter { $0.label.hasPrefix("Battery") }
        let power = model.sensors.power.filter { $0.label.hasPrefix("Battery") }

        MetricCard(title: "Batterie", systemImage: battery.isCharging ? "battery.100.bolt" : "battery.75") {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(battery.percentage)%")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .monospacedDigit()
                    Spacer()
                    Text(battery.isCharging ? "En charge" : "Sur batterie")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: Double(battery.percentage), total: 100)
                    .tint(battery.isCharging ? .green : .accentColor)

                infoRow(battery.isCharging ? "Charge complète dans" : "Autonomie restante",
                        battery.timeRemainingMinutes.map(Formatters.minutes) ?? String(localized: "Calcul en cours…"))

                if battery.isCharging, battery.wattage > 0 {
                    infoRow("Puissance du chargeur", String(format: "%.0f W", battery.wattage))
                }

                infoRow("Santé de la batterie", "\(battery.healthPercent)%")
                infoRow("Cycles", "\(battery.cycleCount)")

                ForEach(temperatures) { reading in
                    sensorRow(reading.label, Formatters.celsius(reading.celsius))
                }
                ForEach(power) { reading in
                    sensorRow(reading.label, String(format: "%.2f %@", reading.value, reading.unit))
                }
            }
        }
    }

    private func infoRow(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.monospacedDigit())
        }
    }

    /// Comme `infoRow`, mais pour un libellé technique de capteur (ex. "Battery")
    /// qui ne doit pas être traité comme une clé de localisation — même
    /// convention que TemperatureCardView/PowerCardView.
    private func sensorRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.monospacedDigit())
        }
    }
}
