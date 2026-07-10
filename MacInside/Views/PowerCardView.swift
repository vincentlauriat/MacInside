import SwiftUI

/// Carte alimentation électrique (tension, courant, puissance) ; état vide si indisponible.
struct PowerCardView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let sensors = model.sensors

        MetricCard(title: "Alimentation", systemImage: "bolt.fill") {
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
            } else if sensors.power.isEmpty {
                Text("Aucune donnée d'alimentation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 4) {
                    ForEach(sensors.power) { reading in
                        HStack {
                            Text(reading.label)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text(String(format: "%.2f %@", reading.value, reading.unit))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
