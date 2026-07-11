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

    var id: String { rawValue }
}
