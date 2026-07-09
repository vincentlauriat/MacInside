import SwiftUI

/// Sous-carte : barre de progression du volume système + texte récapitulatif.
struct StorageSummaryView: View {
    var volume: VolumeStats?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Stockage")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let volume {
                ProgressView(value: volume.usedPercent, total: 100)
                    .tint(.indigo)

                Text("\(Formatters.bytes(volume.usedBytes)) utilisés sur \(Formatters.bytes(volume.totalBytes)) (\(Formatters.bytes(volume.availableBytes)) disponibles)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Volume système indisponible")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
