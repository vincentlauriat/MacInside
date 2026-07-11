import SwiftUI

/// Carte CPU : anneau System/User, top-process, barres par cœur (perf/efficiency).
struct CPUCardView: View {
    @Environment(AppModel.self) private var model

    private let systemColor = Color.orange
    private let userColor = Color.blue
    private let performanceColor = Color.blue
    private let efficiencyColor = Color.teal

    var body: some View {
        let cpu = model.cpu
        let identity = model.identity

        MetricCard(title: identity.chipName.isEmpty ? String(localized: "Processeur") : identity.chipName, systemImage: "cpu") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 16) {
                    CircularGauge(
                        segments: [
                            GaugeSegment(value: cpu.systemPercent, color: systemColor),
                            GaugeSegment(value: cpu.userPercent, color: userColor),
                        ],
                        centerText: Formatters.percent(cpu.totalPercent)
                    )
                    .frame(width: 88, height: 88)

                    VStack(spacing: 6) {
                        LegendRow(color: systemColor, label: "Système", value: Formatters.percent(cpu.systemPercent))
                        LegendRow(color: userColor, label: "Utilisateur", value: Formatters.percent(cpu.userPercent))
                    }
                }

                ProcessListView(entries: cpu.topProcesses, rowCount: 6) { process in
                    Formatters.percent(process.value, decimals: 1)
                }

                if !cpu.perCoreLoad.isEmpty {
                    coreBars(cpu.perCoreLoad, performanceCount: identity.performanceCoreCount)
                }
            }
        }
    }

    private func coreBars(_ loads: [Double], performanceCount: Int) -> some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(loads.enumerated()), id: \.offset) { index, load in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < performanceCount ? performanceColor : efficiencyColor)
                        .frame(height: max(2, geo.size.height * CGFloat(min(max(load, 0), 100)) / 100))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
        .frame(height: 32)
    }
}
