import SwiftUI
import WidgetKit

struct CPUWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "fr.vincentlauriat.macinside.widget.cpu",
                            provider: SnapshotProvider()) { entry in
            CPUWidgetView(entry: entry)
        }
        .configurationDisplayName("Processeur")
        .description("Charge CPU et processus le plus gourmand.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct CPUWidgetView: View {
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

    private func content(_ snapshot: WidgetSnapshot) -> some View {
        let cpu = snapshot.cpu
        return VStack(alignment: .leading, spacing: 6) {
            WidgetHeader(title: "Processeur", systemImage: "cpu")
            WidgetValue(text: Formatters.percent(cpu.totalPercent))

            if !cpu.history.isEmpty {
                WidgetSparkline(values: cpu.history, color: .orange)
                    .frame(height: family == .systemMedium ? 34 : 24)
            }

            if family == .systemMedium {
                HStack(spacing: 12) {
                    detail("Utilisateur", Formatters.percent(cpu.userPercent, decimals: 1))
                    detail("Système", Formatters.percent(cpu.systemPercent, decimals: 1))
                }
            }

            if let name = cpu.topProcessName, let percent = cpu.topProcessPercent {
                HStack(spacing: 4) {
                    // Nom de process : jamais localisé, c'est un identifiant système.
                    Text(name)
                        .font(.caption2)
                        .lineLimit(1)
                    Spacer(minLength: 2)
                    Text(Formatters.percent(percent, decimals: 1))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
            WidgetTimestamp(date: snapshot.capturedAt)
        }
    }

    private func detail(_ label: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption2.monospacedDigit())
        }
    }
}
