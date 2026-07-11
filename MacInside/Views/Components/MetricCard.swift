import SwiftUI

/// Conteneur de carte réutilisable : titre, fond matériel, coins arrondis.
///
/// Deux initialiseurs, même pattern que `Text`/`Label` : un titre statique
/// localisable (`LocalizedStringKey`, ex. "Ventilateurs") pour la plupart des
/// cartes, ou un titre dynamique déjà résolu (`String`, verbatim) pour les
/// cartes dont le titre vient du matériel (ex. le nom de la puce en CPU/GPU) —
/// ce texte-là ne doit surtout pas repasser par la table de localisation.
struct MetricCard<Content: View>: View {
    private let title: Text
    var systemImage: String? = nil
    @ViewBuilder var content: () -> Content

    init(title: LocalizedStringKey, systemImage: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = Text(title)
        self.systemImage = systemImage
        self.content = content
    }

    /// Générique sur `StringProtocol`, avec `@_disfavoredOverload` — sans cet
    /// attribut, un littéral comme `title: "Ventilateurs"` reste ambigu entre
    /// les deux inits et Swift choisit silencieusement CELUI-CI (vérifié
    /// empiriquement : contrairement à une idée reçue, "concret vs générique"
    /// ne suffit PAS à départager un littéral de chaîne entre deux inits avec
    /// le même label). `@_disfavoredOverload` est le mécanisme (non documenté
    /// mais stable, utilisé en interne par `Text`/`Label` eux-mêmes) qui force
    /// la préférence vers l'init `LocalizedStringKey` ci-dessus pour un
    /// littéral, tout en gardant celui-ci pour une vraie valeur dynamique
    /// (ex. le nom de la puce).
    @_disfavoredOverload
    init<S>(title: S, systemImage: String? = nil, @ViewBuilder content: @escaping () -> Content) where S: StringProtocol {
        self.title = Text(title)
        self.systemImage = systemImage
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(.secondary)
                }
                title
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        )
    }
}

/// Ligne libellé/valeur avec pastille de couleur, pour les légendes de jauges.
struct LegendRow: View {
    var color: Color
    var label: LocalizedStringKey
    var value: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.monospacedDigit())
        }
    }
}
