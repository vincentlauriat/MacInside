import SwiftUI

/// Carte Mémoire : anneau Wired/Active/Compressed, top-process par mémoire.
struct MemoryCardView: View {
    @Environment(AppModel.self) private var model

    private let wiredColor = Color.purple
    private let activeColor = Color.blue
    private let compressedColor = Color.orange
    private let availableColor = Color.mint

    var body: some View {
        let memory = model.memory

        MetricCard(title: "Mémoire", systemImage: "memorychip") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 16) {
                    CircularGauge(
                        segments: gaugeSegments(memory),
                        centerText: Formatters.percent(memory.usedPercent)
                    )
                    .frame(width: 88, height: 88)

                    VStack(spacing: 6) {
                        LegendRow(color: wiredColor, label: "Wired", value: Formatters.bytes(memory.wiredBytes))
                        LegendRow(color: activeColor, label: "Active", value: Formatters.bytes(memory.activeBytes))
                        LegendRow(color: compressedColor, label: "Compressée", value: Formatters.bytes(memory.compressedBytes))
                        LegendRow(color: availableColor, label: "Disponible", value: Formatters.bytes(memory.availableBytes))
                    }
                }

                ProcessListView(entries: memory.topProcesses, rowCount: 6) { process in
                    Formatters.bytes(UInt64(max(process.value, 0)))
                }
            }
        }
    }

    private func gaugeSegments(_ memory: MemoryStats) -> [GaugeSegment] {
        let usedTotal = Double(memory.wiredBytes + memory.activeBytes + memory.compressedBytes)
        guard usedTotal > 0, memory.totalBytes > 0 else { return [] }
        let scale = memory.usedPercent / usedTotal
        return [
            GaugeSegment(value: Double(memory.wiredBytes) * scale, color: wiredColor),
            GaugeSegment(value: Double(memory.activeBytes) * scale, color: activeColor),
            GaugeSegment(value: Double(memory.compressedBytes) * scale, color: compressedColor),
        ]
    }
}
