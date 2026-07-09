import SwiftUI

/// Étiquettes compactes affichées dans la barre de menu en mode "icônes
/// séparées" (une par métrique, façon Stats/iStat Menus). Chaque étiquette
/// lit `AppModel` depuis l'environnement de la scène `MenuBarExtra` associée.

struct CPUMenuBarLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Label(Formatters.percent(model.cpu.totalPercent), systemImage: "cpu")
            .monospacedDigit()
    }
}

struct MemoryMenuBarLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Label(Formatters.percent(model.memory.usedPercent), systemImage: "memorychip")
            .monospacedDigit()
    }
}

struct NetworkMenuBarLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let network = model.network
        Label(
            "↓\(Formatters.bytesPerSecond(network.downloadBytesPerSec)) ↑\(Formatters.bytesPerSecond(network.uploadBytesPerSec))",
            systemImage: "network"
        )
        .monospacedDigit()
    }
}

struct DiskMenuBarLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Label(Formatters.percent(model.disk.systemVolume?.usedPercent ?? 0), systemImage: "internaldrive")
            .monospacedDigit()
    }
}

struct BatteryMenuBarLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Label("\(model.battery.percentage)%", systemImage: model.battery.isCharging ? "battery.100.bolt" : "battery.75")
            .monospacedDigit()
    }
}

struct GPUMenuBarLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Label(Formatters.percent(Double(model.gpu.deviceUtilizationPercent)), systemImage: "cpu.fill")
            .monospacedDigit()
    }
}
