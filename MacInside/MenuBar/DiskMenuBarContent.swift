import SwiftUI

/// Contenu du dropdown menu bar "Disque" en mode icônes séparées : volume
/// système + volumes externes, dans le chrome `MetricCard` standard (ces
/// sous-vues n'ont pas de titre de carte propre, elles sont normalement
/// nichées dans Mémoire/Débit réseau).
struct DiskMenuBarContent: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        MetricCard(title: "Disques", systemImage: "internaldrive") {
            VStack(spacing: 10) {
                StorageSummaryView(volume: model.disk.systemVolume)
                ExternalVolumesView(volumes: model.disk.externalVolumes)
            }
        }
        .padding(4)
        .frame(width: 300)
    }
}
