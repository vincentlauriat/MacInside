import SwiftUI

/// Carte débit réseau : sparklines download/upload, sous-carte volumes externes.
struct NetworkUsageCardView: View {
    @Environment(AppModel.self) private var model

    private let downloadColor = Color.blue
    private let uploadColor = Color.orange

    var body: some View {
        let network = model.network

        MetricCard(title: "Débit réseau", systemImage: "arrow.up.arrow.down") {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Download")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Formatters.bytesPerSecond(network.downloadBytesPerSec))
                            .font(.caption.monospacedDigit())
                    }
                    SparklineChart(values: network.downloadHistory, color: downloadColor)
                        .frame(height: 40)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Upload")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Formatters.bytesPerSecond(network.uploadBytesPerSec))
                            .font(.caption.monospacedDigit())
                    }
                    SparklineChart(values: network.uploadHistory, color: uploadColor)
                        .frame(height: 40)
                }

                HStack {
                    Text("Total depuis le lancement")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("↓ \(Formatters.bytes(network.totalDownloadBytes))  ↑ \(Formatters.bytes(network.totalUploadBytes))")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                ExternalVolumesView(volumes: model.disk.externalVolumes)
            }
        }
    }
}
