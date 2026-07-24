import SwiftUI
import UniformTypeIdentifiers
import AppKit

/// Grille "masonry" maison plutôt qu'un `LazyVGrid` : dans un `LazyVGrid`,
/// toutes les cartes d'une même ligne partagent la hauteur de la plus haute
/// d'entre elles, ce qui crée un grand vide sous les cartes plus courtes
/// (ex. CPU au-dessus de Ventilateurs). Ici chaque colonne empile ses cartes
/// indépendamment des autres colonnes, sans hauteur de ligne imposée.
///
/// L'ordre des cartes est piloté par `AppSettings.dashboardCardOrder` et
/// modifiable par glisser-déposer (chaque carte porte son `DashboardCardKind`
/// comme identité de drag).
struct DashboardView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings

    private let minColumnWidth: CGFloat = 260
    private let spacing: CGFloat = 16
    private let horizontalPadding: CGFloat = 20

    @State private var draggedKind: DashboardCardKind?

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

    private var orderedKinds: [DashboardCardKind] {
        settings.dashboardCardOrder
            .filter { $0 != .battery || model.battery.isPresent }
            .filter { !settings.hiddenDashboardCards.contains($0) }
    }

    @ViewBuilder
    private func cardView(for kind: DashboardCardKind) -> some View {
        switch kind {
        case .cpu: CPUCardView()
        case .memory: MemoryCardView()
        case .storage: StorageCardView()
        case .networkIdentity: NetworkIdentityCardView()
        case .networkUsage: NetworkUsageCardView()
        case .fans: FansCardView()
        case .temperature: TemperatureCardView()
        case .power: PowerCardView()
        case .battery: BatteryCardView()
        case .accessoryBatteries: AccessoryBatteryCardView()
        }
    }

    private func masonry(width: CGFloat) -> some View {
        let kinds = orderedKinds
        let columnCount = max(1, Int((width + spacing) / (minColumnWidth + spacing)))
        var columns: [[DashboardCardKind]] = Array(repeating: [], count: columnCount)
        for (index, kind) in kinds.enumerated() {
            columns[index % columnCount].append(kind)
        }

        return HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columnCount, id: \.self) { column in
                VStack(spacing: spacing) {
                    ForEach(columns[column]) { kind in
                        draggableCard(kind)
                    }
                }
            }
        }
    }

    private func draggableCard(_ kind: DashboardCardKind) -> some View {
        cardView(for: kind)
            .overlay(alignment: .topTrailing) {
                dragHandle(kind)
            }
            .opacity(draggedKind == kind ? 0.4 : 1)
            .onDrop(of: [.text], delegate: CardDropDelegate(
                target: kind,
                draggedKind: $draggedKind,
                move: moveCard
            ))
    }

    /// Seule cette poignée déclenche le glisser, pas la carte entière : poser
    /// `.onDrag` sur toute la surface de la carte la faisait entrer en
    /// conflit avec ses propres interactions (menu contextuel des process,
    /// boutons), rendant le déplacement imprécis. Le curseur "main" au survol
    /// confirme visuellement la zone réellement saisissable.
    private func dragHandle(_ kind: DashboardCardKind) -> some View {
        Image(systemName: "line.3.horizontal")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .padding(10)
            .contentShape(Rectangle())
            .onHover { isHovering in
                if isHovering {
                    NSCursor.openHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .onDrag {
                draggedKind = kind
                return NSItemProvider(object: kind.rawValue as NSString)
            }
    }

    /// Déplace `kind` juste avant `target` dans l'ordre persisté — les cartes
    /// masquées (ex. Batterie absente) restent à leur position dans l'ordre
    /// stocké, seul l'ordre relatif des cartes visibles change. Animé : sans
    /// ça, la grille se réarrangeait d'un coup sec (chaque carte peut changer
    /// de colonne, pas seulement de position), ce qui rendait le résultat du
    /// glisser difficile à suivre.
    private func moveCard(_ kind: DashboardCardKind, before target: DashboardCardKind) {
        guard kind != target else { return }
        var order = settings.dashboardCardOrder
        guard let fromIndex = order.firstIndex(of: kind) else { return }
        order.remove(at: fromIndex)
        let toIndex = order.firstIndex(of: target) ?? order.count
        order.insert(kind, at: toIndex)
        withAnimation(.easeInOut(duration: 0.2)) {
            settings.dashboardCardOrder = order
        }
    }
}

private struct CardDropDelegate: DropDelegate {
    let target: DashboardCardKind
    @Binding var draggedKind: DashboardCardKind?
    let move: (DashboardCardKind, DashboardCardKind) -> Void

    func dropEntered(info: DropInfo) {
        guard let draggedKind, draggedKind != target else { return }
        move(draggedKind, target)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedKind = nil
        return true
    }
}
