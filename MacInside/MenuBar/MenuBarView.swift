import SwiftUI

/// Dropdown menu bar : résumé condensé + accès au tableau de bord.
struct MenuBarView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let cpu = model.cpu
        let memory = model.memory
        let network = model.network

        VStack(alignment: .leading, spacing: 10) {
            Text(model.identity.hostname.isEmpty ? "MacInside" : model.identity.hostname)
                .font(.headline)

            VStack(spacing: 6) {
                summaryRow(icon: "cpu", label: "CPU", value: Formatters.percent(cpu.totalPercent))
                summaryRow(icon: "memorychip", label: "Mémoire", value: Formatters.percent(memory.usedPercent))
                summaryRow(icon: "arrow.down", label: "Download", value: Formatters.bytesPerSecond(network.downloadBytesPerSec))
                summaryRow(icon: "arrow.up", label: "Upload", value: Formatters.bytesPerSecond(network.uploadBytesPerSec))
            }

            Divider()

            Button {
                showDashboard()
            } label: {
                Label("Ouvrir le tableau de bord", systemImage: "rectangle.grid.2x2")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quitter", systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(width: 240)
    }

    private func showDashboard() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { !($0 is NSPanel) }) {
            window.makeKeyAndOrderFront(nil)
        }
    }

    private func summaryRow(icon: String, label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.monospacedDigit())
        }
    }
}
