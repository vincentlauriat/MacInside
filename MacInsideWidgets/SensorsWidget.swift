import SwiftUI
import WidgetKit

struct SensorsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "fr.vincentlauriat.macinside.widget.sensors",
                            provider: SnapshotProvider()) { entry in
            SensorsWidgetView(entry: entry)
        }
        .configurationDisplayName("Capteurs")
        .description("Températures SMC et ventilateurs.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SensorsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                content(snapshot)
            } else {
                WidgetUnavailable()
            }
        }
        .widgetChrome()
    }

    @ViewBuilder
    private func content(_ snapshot: WidgetSnapshot) -> some View {
        let sensors = snapshot.sensors
        VStack(alignment: .leading, spacing: 6) {
            WidgetHeader(title: "Capteurs", systemImage: "thermometer.medium")

            if !sensors.available {
                Text("Capteurs indisponibles sur ce Mac")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            } else if let maxCelsius = sensors.maxCelsius {
                WidgetValue(text: Formatters.celsius(maxCelsius))
                if let label = sensors.maxLabel {
                    // Libellé de capteur SMC : identifiant technique, non traduit.
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if family == .systemMedium {
                    VStack(spacing: 2) {
                        ForEach(sensors.readings.dropFirst(), id: \.label) { reading in
                            HStack(spacing: 4) {
                                Text(reading.label)
                                    .font(.system(size: 10))
                                    .lineLimit(1)
                                Spacer(minLength: 2)
                                Text(Formatters.celsius(reading.celsius))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if sensors.hasFans, !sensors.fanRPMs.isEmpty {
                    Text(fanSummary(sensors.fanRPMs))
                        .font(.system(size: 10).monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if !sensors.hasFans {
                    Text("Pas de ventilateur sur ce Mac")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            } else {
                Text("Aucune donnée de température")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }

            WidgetTimestamp(date: snapshot.capturedAt)
        }
    }

    /// Un seul ventilateur → sa vitesse ; plusieurs → la plus élevée, celle qui
    /// renseigne sur la sollicitation thermique de la machine.
    private func fanSummary(_ rpms: [Int]) -> String {
        let peak = rpms.max() ?? 0
        return rpms.count > 1
            ? String(localized: "\(rpms.count) ventilateurs · max \(peak) tr/min")
            : String(localized: "\(peak) tr/min")
    }
}
