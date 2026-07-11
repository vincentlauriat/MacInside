import SwiftUI

/// Carte Stockage : volume système + volumes externes montés.
struct StorageCardView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        MetricCard(title: "Stockage", systemImage: "internaldrive") {
            VStack(spacing: 10) {
                StorageSummaryView(volume: model.disk.systemVolume)
                ExternalVolumesView(volumes: model.disk.externalVolumes)
            }
        }
    }
}
