import SwiftUI
import WidgetKit

struct MemoryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "fr.vincentlauriat.macinside.widget.memory",
                            provider: SnapshotProvider()) { entry in
            MemoryWidgetView(entry: entry)
        }
        .configurationDisplayName("Mémoire")
        .description("Mémoire utilisée et application la plus gourmande.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MemoryWidgetView: View {
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
        let memory = snapshot.memory
        return VStack(alignment: .leading, spacing: 6) {
            WidgetHeader(title: "Mémoire", systemImage: "memorychip")
            WidgetValue(text: Formatters.percent(memory.usedPercent))

            ProgressView(value: min(memory.usedPercent, 100), total: 100)
                .tint(.blue)

            if family == .systemMedium, !memory.history.isEmpty {
                WidgetSparkline(values: memory.history, color: .blue)
                    .frame(height: 30)
            }

            Text("\(Formatters.bytes(memory.usedBytes)) / \(Formatters.bytes(memory.totalBytes))")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let name = memory.topProcessName, let bytes = memory.topProcessBytes {
                HStack(spacing: 4) {
                    Text(name)
                        .font(.caption2)
                        .lineLimit(1)
                    Spacer(minLength: 2)
                    Text(Formatters.bytes(UInt64(max(bytes, 0))))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
            WidgetTimestamp(date: snapshot.capturedAt)
        }
    }
}
