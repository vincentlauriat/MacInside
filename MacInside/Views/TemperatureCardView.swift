import SwiftUI

/// Carte capteurs de température ; état vide si indisponible.
struct TemperatureCardView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let sensors = model.sensors
        // Les capteurs "Battery"/"Battery 2" (TB0T/Ts0P/Ts1P) sont affichés
        // dans BatteryCardView plutôt qu'ici, pour éviter la même duplication
        // déjà corrigée une fois pour les volumes de stockage (cf. MEMORY.md).
        let temperatures = sensors.temperatures.filter { !$0.label.hasPrefix("Battery") }

        MetricCard(title: "Capteurs", systemImage: "thermometer.medium") {
            if !sensors.available {
                VStack(spacing: 6) {
                    Image(systemName: "thermometer.slash")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Capteurs indisponibles sur ce Mac")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else if temperatures.isEmpty {
                Text("Aucune donnée de température")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                // Pas de sous-scroll : la carte s'étend à toute la hauteur du
                // contenu, la grille masonry n'impose plus de hauteur de ligne
                // partagée avec les autres colonnes — c'est la fenêtre entière
                // (ScrollView de DashboardView) qui défile si besoin.
                VStack(spacing: 4) {
                    if !sensors.temperatureHistory.isEmpty {
                        SparklineChart(values: sensors.temperatureHistory, color: .red)
                            .frame(height: 32)
                            .padding(.bottom, 6)
                    }
                    ForEach(temperatures) { reading in
                        HStack {
                            Text(reading.label)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(Formatters.celsius(reading.celsius))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
