import SwiftUI

/// Carte batterie : pourcentage, état de charge, temps restant, cycles, santé.
/// Masquée si absente (Mac de bureau).
struct BatteryCardView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let battery = model.battery

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
                        battery.timeRemainingMinutes.map(Formatters.minutes) ?? "Calcul en cours…")

                if battery.isCharging, battery.wattage > 0 {
                    infoRow("Puissance du chargeur", String(format: "%.0f W", battery.wattage))
                }

                infoRow("Santé de la batterie", "\(battery.healthPercent)%")
                infoRow("Cycles", "\(battery.cycleCount)")
            }
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
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
