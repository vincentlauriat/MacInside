import SwiftUI

/// Carte identité réseau : hostname, adresse locale/publique, pays.
struct NetworkIdentityCardView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let network = model.network
        let identity = model.identity

        MetricCard(title: "Identité réseau", systemImage: "network") {
            VStack(alignment: .leading, spacing: 14) {
                VStack(spacing: 8) {
                    row("Hostname", identity.hostname)
                    row("Interface", [network.interfaceType, network.interfaceName]
                        .filter { !$0.isEmpty }.joined(separator: " · "))
                    row("Adresse locale", network.localAddress)
                    row("Adresse publique", network.publicAddress)
                    row("Pays", network.countryCode)
                    row("Passerelle", network.gatewayAddress)
                    row("Masque de sous-réseau", network.subnetMask)
                    row("Adresse MAC", network.macAddress)
                }

                GPUUtilizationView(gpu: model.gpu, chipName: identity.chipName)
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value.isEmpty ? "—" : value)
                .font(.caption.monospacedDigit())
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}
