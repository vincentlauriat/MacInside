import SwiftUI

/// Carte batteries des accessoires Bluetooth connectés (AirPods, Magic
/// Mouse/Keyboard/Trackpad...) ; état vide si aucun accessoire avec batterie
/// n'est actuellement connecté.
struct AccessoryBatteryCardView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let accessories = model.accessoryBatteries.accessories
        let names = Set(accessories.map(\.name)).sorted()

        MetricCard(title: "Accessoires", systemImage: "cable.connector") {
            if accessories.isEmpty {
                Text("Aucun accessoire Bluetooth avec batterie connecté")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(names, id: \.self) { name in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(name)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            ForEach(readings(for: name, in: accessories)) { reading in
                                HStack {
                                    Text(partLabel(reading.part))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(reading.percent)%")
                                        .font(.caption2.monospacedDigit())
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /// Ordre stable (Gauche, Droite, Boîtier, Batterie) : l'ordre d'itération
    /// d'un dictionnaire JSON désérialisé n'est pas garanti, il varierait sinon
    /// d'un rafraîchissement à l'autre.
    private func readings(for name: String, in accessories: [AccessoryBatteryReading]) -> [AccessoryBatteryReading] {
        accessories
            .filter { $0.name == name }
            .sorted { sortRank($0.part) < sortRank($1.part) }
    }

    private func sortRank(_ part: String) -> Int {
        switch part {
        case "Left": return 0
        case "Right": return 1
        case "Case": return 2
        default: return 3
        }
    }

    private func partLabel(_ part: String) -> LocalizedStringKey {
        switch part {
        case "Left": return "Gauche"
        case "Right": return "Droite"
        case "Case": return "Boîtier"
        default: return "Batterie"
        }
    }
}
