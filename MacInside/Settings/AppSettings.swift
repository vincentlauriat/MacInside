import SwiftUI
import Observation

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
    var label: String {
        switch self {
        case .system: return "Système"
        case .light:  return "Clair"
        case .dark:   return "Sombre"
        }
    }
}

/// Style de la barre de menu : un seul dropdown combiné (historique) ou une
/// icône compacte par métrique, façon Stats/iStat Menus (chaque icône ouvre
/// son propre dropdown détaillé).
enum MenuBarMode: String, CaseIterable, Identifiable {
    case combined, separate
    var id: String { rawValue }
    var label: String {
        switch self {
        case .combined: return "Combiné"
        case .separate: return "Icônes séparées"
        }
    }
}

@Observable
@MainActor
final class AppSettings {
    var appearanceRaw: String {
        didSet { UserDefaults.standard.set(appearanceRaw, forKey: "appearance") }
    }
    var refreshInterval: Double {
        didSet { UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval") }
    }
    var menuBarModeRaw: String {
        didSet { UserDefaults.standard.set(menuBarModeRaw, forKey: "menuBarMode") }
    }
    var showCPUMenuExtra: Bool { didSet { UserDefaults.standard.set(showCPUMenuExtra, forKey: "showCPUMenuExtra") } }
    var showMemoryMenuExtra: Bool { didSet { UserDefaults.standard.set(showMemoryMenuExtra, forKey: "showMemoryMenuExtra") } }
    var showNetworkMenuExtra: Bool { didSet { UserDefaults.standard.set(showNetworkMenuExtra, forKey: "showNetworkMenuExtra") } }
    var showDiskMenuExtra: Bool { didSet { UserDefaults.standard.set(showDiskMenuExtra, forKey: "showDiskMenuExtra") } }
    var showBatteryMenuExtra: Bool { didSet { UserDefaults.standard.set(showBatteryMenuExtra, forKey: "showBatteryMenuExtra") } }
    var showGPUMenuExtra: Bool { didSet { UserDefaults.standard.set(showGPUMenuExtra, forKey: "showGPUMenuExtra") } }
    var dashboardCardOrderRaw: String {
        didSet { UserDefaults.standard.set(dashboardCardOrderRaw, forKey: "dashboardCardOrder") }
    }

    init() {
        let defaults = UserDefaults.standard
        appearanceRaw = defaults.string(forKey: "appearance") ?? AppearanceMode.system.rawValue
        let storedInterval = defaults.double(forKey: "refreshInterval")
        refreshInterval = storedInterval > 0 ? storedInterval : 1.0
        menuBarModeRaw = defaults.string(forKey: "menuBarMode") ?? MenuBarMode.combined.rawValue

        showCPUMenuExtra = defaults.object(forKey: "showCPUMenuExtra") as? Bool ?? true
        showMemoryMenuExtra = defaults.object(forKey: "showMemoryMenuExtra") as? Bool ?? true
        showNetworkMenuExtra = defaults.object(forKey: "showNetworkMenuExtra") as? Bool ?? true
        showDiskMenuExtra = defaults.object(forKey: "showDiskMenuExtra") as? Bool ?? false
        showBatteryMenuExtra = defaults.object(forKey: "showBatteryMenuExtra") as? Bool ?? false
        showGPUMenuExtra = defaults.object(forKey: "showGPUMenuExtra") as? Bool ?? false
        dashboardCardOrderRaw = defaults.string(forKey: "dashboardCardOrder") ?? ""
    }

    var appearance: AppearanceMode { AppearanceMode(rawValue: appearanceRaw) ?? .system }
    var menuBarMode: MenuBarMode { MenuBarMode(rawValue: menuBarModeRaw) ?? .combined }
    var menuBarModeIsCombined: Bool { menuBarMode == .combined }

    /// Ordre des cartes du dashboard, choisi par l'utilisateur via glisser-déposer.
    /// Les nouvelles cartes (ajoutées dans une version ultérieure) sont
    /// automatiquement ajoutées à la fin si elles sont absentes de l'ordre stocké.
    var dashboardCardOrder: [DashboardCardKind] {
        get {
            var order = dashboardCardOrderRaw
                .split(separator: ",")
                .compactMap { DashboardCardKind(rawValue: String($0)) }
            for kind in DashboardCardKind.allCases where !order.contains(kind) {
                order.append(kind)
            }
            return order
        }
        set { dashboardCardOrderRaw = newValue.map(\.rawValue).joined(separator: ",") }
    }
}
