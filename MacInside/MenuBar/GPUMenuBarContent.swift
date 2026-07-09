import SwiftUI

/// Contenu du dropdown menu bar "GPU" en mode icônes séparées.
struct GPUMenuBarContent: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        MetricCard(title: model.identity.chipName.isEmpty ? "GPU" : model.identity.chipName, systemImage: "cpu.fill") {
            GPUUtilizationView(gpu: model.gpu, chipName: "", showsHeader: false)
        }
        .padding(4)
        .frame(width: 300)
    }
}
