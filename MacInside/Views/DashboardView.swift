import SwiftUI

/// Grille "masonry" maison plutôt qu'un `LazyVGrid` : dans un `LazyVGrid`,
/// toutes les cartes d'une même ligne partagent la hauteur de la plus haute
/// d'entre elles, ce qui crée un grand vide sous les cartes plus courtes
/// (ex. CPU au-dessus de Ventilateurs). Ici chaque colonne empile ses cartes
/// indépendamment des autres colonnes, sans hauteur de ligne imposée.
struct DashboardView: View {
    @Environment(AppModel.self) private var model

    private let minColumnWidth: CGFloat = 260
    private let spacing: CGFloat = 16
    private let horizontalPadding: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: spacing) {
                    HeaderView()
                    masonry(width: geo.size.width - horizontalPadding * 2)
                }
                .padding(horizontalPadding)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var cards: [AnyView] {
        var list: [AnyView] = [
            AnyView(CPUCardView()),
            AnyView(MemoryCardView()),
            AnyView(NetworkIdentityCardView()),
            AnyView(NetworkUsageCardView()),
            AnyView(FansCardView()),
            AnyView(TemperatureCardView()),
            AnyView(PowerCardView()),
        ]
        if model.battery.isPresent {
            list.append(AnyView(BatteryCardView()))
        }
        return list
    }

    private func masonry(width: CGFloat) -> some View {
        let columnCount = max(1, Int((width + spacing) / (minColumnWidth + spacing)))
        var columns: [[AnyView]] = Array(repeating: [], count: columnCount)
        for (index, card) in cards.enumerated() {
            columns[index % columnCount].append(card)
        }

        return HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columnCount, id: \.self) { column in
                VStack(spacing: spacing) {
                    ForEach(0..<columns[column].count, id: \.self) { row in
                        columns[column][row]
                    }
                }
            }
        }
    }
}
