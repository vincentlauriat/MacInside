import SwiftUI

/// Sous-carte : liste des volumes externes montés (ou message si vide).
struct ExternalVolumesView: View {
    var volumes: [VolumeStats]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Volumes externes")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if volumes.isEmpty {
                Text("Aucun volume externe connecté")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(volumes) { volume in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(volume.name)
                                    .font(.caption)
                                Spacer()
                                Text("\(Formatters.bytes(volume.usedBytes)) / \(Formatters.bytes(volume.totalBytes))")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            ProgressView(value: volume.usedPercent, total: 100)
                                .tint(.teal)
                        }
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
