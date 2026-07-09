import SwiftUI

/// Carte ventilateurs + capteurs de température ; état vide si indisponible.
struct SensorsCardView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let sensors = model.sensors

        MetricCard(title: "Ventilateurs & Capteurs", systemImage: "thermometer.medium") {
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
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    if !sensors.fans.isEmpty {
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

                    if !sensors.temperatures.isEmpty {
                        // Pas de sous-scroll : la carte s'étend à toute la hauteur du
                        // contenu, la grille masonry n'impose plus de hauteur de ligne
                        // partagée avec les autres colonnes — c'est la fenêtre entière
                        // (ScrollView de DashboardView) qui défile si besoin.
                        VStack(spacing: 4) {
                            ForEach(sensors.temperatures) { reading in
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

                    if !sensors.power.isEmpty {
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
    }
}
