import SwiftUI
import WidgetKit

struct BatteryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "fr.vincentlauriat.macinside.widget.battery",
                            provider: SnapshotProvider()) { entry in
            BatteryWidgetView(entry: entry)
        }
        .configurationDisplayName("Batterie")
        .description("Niveau, autonomie, santé et température de la batterie.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct BatteryWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SnapshotEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                if let battery = snapshot.battery {
                    content(battery, capturedAt: snapshot.capturedAt)
                } else {
                    // Mac de bureau : distinct d'une batterie à 0 % ou d'une
                    // absence de données.
                    VStack(spacing: 4) {
                        Image(systemName: "powerplug")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("Pas de batterie sur ce Mac")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                WidgetUnavailable(reason: entry.result)
            }
        }
        .widgetChrome()
    }

    private func content(_ battery: WidgetSnapshot.Battery, capturedAt: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            WidgetHeader(title: "Batterie",
                         systemImage: battery.isCharging ? "battery.100.bolt" : "battery.75")
            WidgetValue(text: "\(battery.percentage)%")

            ProgressView(value: Double(battery.percentage), total: 100)
                .tint(battery.isCharging ? .green : .accentColor)

            if let minutes = battery.timeRemainingMinutes {
                row(battery.isCharging ? "Charge complète dans" : "Autonomie restante",
                    Formatters.minutes(minutes))
            } else {
                // macOS lui-même n'a pas toujours d'estimation (cf. `pmset -g batt`
                // → « no estimate ») : le dire plutôt que d'inventer un calcul.
                row(battery.isCharging ? "Charge complète dans" : "Autonomie restante",
                    String(localized: "Calcul en cours…"))
            }

            if family == .systemMedium {
                row("Santé de la batterie", "\(battery.healthPercent)%")
                row("Cycles", "\(battery.cycleCount)")
            }

            if let celsius = battery.celsius {
                row("Température", Formatters.celsius(celsius))
            }

            Spacer(minLength: 0)
            WidgetTimestamp(date: capturedAt)
        }
    }

    private func row(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 2)
            Text(value)
                .font(.caption2.monospacedDigit())
                .lineLimit(1)
        }
    }
}
