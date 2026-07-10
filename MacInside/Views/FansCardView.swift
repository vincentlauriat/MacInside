import SwiftUI

/// Carte ventilateurs ; état vide si indisponible ou absent sur ce Mac.
struct FansCardView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let sensors = model.sensors

        MetricCard(title: "Ventilateurs", systemImage: "fan") {
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
            } else if !sensors.hasFans {
                Text("Pas de ventilateur sur ce Mac")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(sensors.fans) { fan in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(fan.label)
                                    .font(.caption)
                                Spacer()
                                Text("\(fan.rpm) tr/min")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            ProgressView(value: fan.percent, total: 100)
                                .tint(.cyan)
                        }
                    }
                }
            }
        }
    }
}
