import SwiftUI

/// Contenu du dropdown menu bar "Réseau" en mode icônes séparées : identité
/// réseau (inclut la sous-carte GPU) + débit. Léger doublon avec le dropdown
/// "GPU" si les deux sont activés en même temps — accepté pour rester simple.
struct NetworkMenuBarContent: View {
    var body: some View {
        VStack(spacing: 12) {
            NetworkIdentityCardView()
            NetworkUsageCardView()
        }
        .padding(4)
        .frame(width: 300)
    }
}
