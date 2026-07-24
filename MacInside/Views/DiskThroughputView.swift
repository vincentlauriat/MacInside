import SwiftUI

/// Sous-carte : débit lecture/écriture disque agrégé (tous disques confondus) + mini-graphes.
struct DiskThroughputView: View {
    var disk: DiskStats

    private let readColor = Color.green
    private let writeColor = Color.purple

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Débit disque")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Lecture")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Formatters.bytesPerSecond(disk.readBytesPerSec))
                        .font(.caption2.monospacedDigit())
                }
                SparklineChart(values: disk.readHistory, color: readColor)
                    .frame(height: 32)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Écriture")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Formatters.bytesPerSecond(disk.writeBytesPerSec))
                        .font(.caption2.monospacedDigit())
                }
                SparklineChart(values: disk.writeHistory, color: writeColor)
                    .frame(height: 32)
            }

            HStack {
                Text("Total depuis le lancement")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("↓ \(Formatters.bytes(disk.totalReadBytes))  ↑ \(Formatters.bytes(disk.totalWriteBytes))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
