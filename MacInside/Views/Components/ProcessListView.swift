import SwiftUI

/// Liste de top-process à hauteur fixe (`rowCount` lignes, complétées par des
/// lignes invisibles si moins d'entrées sont disponibles). Évite que la carte
/// parente change de hauteur d'un rafraîchissement à l'autre selon le nombre
/// de process effectivement remontés.
///
/// Menu contextuel (clic droit) par ligne : terminer/forcer l'arrêt (avec
/// confirmation, action destructive) et baisser la priorité — capacité propre
/// à la distribution Developer ID non-sandboxée de MacInside.
struct ProcessListView: View {
    let entries: [ProcessUsageEntry]
    let rowCount: Int
    let valueText: (ProcessUsageEntry) -> String

    @State private var pendingTermination: (entry: ProcessUsageEntry, force: Bool)?

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
                .contentShape(Rectangle())
                .contextMenu {
                    if index < entries.count {
                        processMenu(for: entries[index])
                    }
                }
            }
        }
        .confirmationDialog(
            confirmationTitle,
            isPresented: isPendingTerminationPresented,
            titleVisibility: .visible
        ) {
            if let pendingTermination {
                Button(pendingTermination.force ? String(localized: "Forcer l'arrêt") : String(localized: "Terminer"), role: .destructive) {
                    ProcessMonitor.terminate(pid: pendingTermination.entry.pid, force: pendingTermination.force)
                    self.pendingTermination = nil
                }
                Button("Annuler", role: .cancel) { self.pendingTermination = nil }
            }
        }
    }

    @ViewBuilder
    private func processMenu(for process: ProcessUsageEntry) -> some View {
        Button("Baisser la priorité") {
            ProcessMonitor.lowerPriority(pid: process.pid)
        }
        Divider()
        Button("Terminer") {
            pendingTermination = (process, false)
        }
        Button("Forcer l'arrêt", role: .destructive) {
            pendingTermination = (process, true)
        }
    }

    private var confirmationTitle: String {
        guard let pendingTermination else { return "" }
        return pendingTermination.force
            ? String(localized: "Forcer l'arrêt de « \(pendingTermination.entry.name) » ?")
            : String(localized: "Terminer « \(pendingTermination.entry.name) » ?")
    }

    private var isPendingTerminationPresented: Binding<Bool> {
        Binding(get: { pendingTermination != nil }, set: { if !$0 { pendingTermination = nil } })
    }
}
