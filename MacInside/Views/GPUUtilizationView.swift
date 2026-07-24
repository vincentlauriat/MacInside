import SwiftUI

/// Sous-carte d'utilisation GPU (barres + détail), affichée sous l'identité
/// réseau — masquée si `GPUStats.available` est faux (service IOAccelerator
/// introuvable).
struct GPUUtilizationView: View {
    let gpu: GPUStats
    let chipName: String
    var showsHeader: Bool = true

    var body: some View {
        if gpu.available {
            VStack(alignment: .leading, spacing: 10) {
                if showsHeader {
                    Text(chipName.isEmpty ? "GPU" : chipName)
                        .font(.subheadline.weight(.semibold))
                }

                labeledBar("Utilisation", Double(gpu.deviceUtilizationPercent))
                labeledBar("Utilisation mémoire", gpu.memoryUsagePercent)

                if !gpu.loadHistory.isEmpty {
                    SparklineChart(values: gpu.loadHistory, color: .pink)
                        .frame(height: 32)
                }

                VStack(spacing: 6) {
                    row("Utilisation appareil %", "\(gpu.deviceUtilizationPercent)")
                    row("Utilisation renderer %", "\(gpu.rendererUtilizationPercent)")
                    row("Utilisation tiler %", "\(gpu.tilerUtilizationPercent)")
                    row("Mémoire système utilisée", Formatters.bytes(gpu.inUseSystemMemoryBytes))
                    row("Mémoire système allouée", Formatters.bytes(gpu.allocSystemMemoryBytes))
                    row("Nombre de récupérations", "\(gpu.recoveryCount)")
                }
            }
        }
    }

    private func labeledBar(_ label: LocalizedStringKey, _ percent: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Formatters.percent(percent))
                    .font(.caption.monospacedDigit())
            }
            ProgressView(value: min(max(percent, 0), 100), total: 100)
        }
    }

    private func row(_ label: LocalizedStringKey, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption2.monospacedDigit())
        }
    }
}
