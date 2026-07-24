import Foundation

/// Identifie chaque carte du dashboard indépendamment de sa vue SwiftUI, pour
/// permettre à `AppSettings` de persister un ordre choisi par l'utilisateur
/// (glisser-déposer dans `DashboardView`).
enum DashboardCardKind: String, CaseIterable, Identifiable {
    case cpu
    case memory
    case storage
    case networkIdentity
    case networkUsage
    case fans
    case temperature
    case power
    case battery
    case accessoryBatteries

    var id: String { rawValue }

    /// Libellé affiché dans les Réglages (section « Cartes du dashboard »),
    /// identique au titre de la carte correspondante (`MetricCard.title`) —
    /// même texte, donc même clé dédupliquée dans le catalogue de chaînes.
    var label: String {
        switch self {
        case .cpu: return String(localized: "Processeur")
        case .memory: return String(localized: "Mémoire")
        case .storage: return String(localized: "Stockage")
        case .networkIdentity: return String(localized: "Identité réseau")
        case .networkUsage: return String(localized: "Débit réseau")
        case .fans: return String(localized: "Ventilateurs")
        case .temperature: return String(localized: "Capteurs")
        case .power: return String(localized: "Alimentation")
        case .battery: return String(localized: "Batterie")
        case .accessoryBatteries: return String(localized: "Accessoires")
        }
    }
}
