import SwiftUI

/// Liste de top-process à hauteur fixe (`rowCount` lignes, complétées par des
/// lignes invisibles si moins d'entrées sont disponibles). Évite que la carte
/// parente change de hauteur d'un rafraîchissement à l'autre selon le nombre
/// de process effectivement remontés.
struct ProcessListView: View {
    let entries: [ProcessUsageEntry]
    let rowCount: Int
    let valueText: (ProcessUsageEntry) -> String

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<rowCount, id: \.self) { index in
                HStack {
                    if index < entries.count {
                        let process = entries[index]
                        Text(process.name)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Text(valueText(process))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    } else {
                        Text(" ")
                            .font(.caption)
                    }
                }
            }
        }
    }
}
