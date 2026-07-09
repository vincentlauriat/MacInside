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

                labeledBar("Utilization", Double(gpu.deviceUtilizationPercent))
                labeledBar("Memory Usage", gpu.memoryUsagePercent)

                VStack(spacing: 6) {
                    row("Device Utilization %", "\(gpu.deviceUtilizationPercent)")
                    row("Renderer Utilization %", "\(gpu.rendererUtilizationPercent)")
                    row("Tiler Utilization %", "\(gpu.tilerUtilizationPercent)")
                    row("System Memory in Use", Formatters.bytes(gpu.inUseSystemMemoryBytes))
                    row("Alloc System Memory", Formatters.bytes(gpu.allocSystemMemoryBytes))
                    row("Recovery Count", "\(gpu.recoveryCount)")
                }
            }
        }
    }

    private func labeledBar(_ label: String, _ percent: Double) -> some View {
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

    private func row(_ label: String, _ value: String) -> some View {
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
