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

@Observable
@MainActor
final class AppSettings {
    var appearanceRaw: String {
        didSet { UserDefaults.standard.set(appearanceRaw, forKey: "appearance") }
    }
    var refreshInterval: Double {
        didSet { UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval") }
    }

    init() {
        appearanceRaw = UserDefaults.standard.string(forKey: "appearance") ?? AppearanceMode.system.rawValue
        let storedInterval = UserDefaults.standard.double(forKey: "refreshInterval")
        refreshInterval = storedInterval > 0 ? storedInterval : 1.0
    }

    var appearance: AppearanceMode { AppearanceMode(rawValue: appearanceRaw) ?? .system }
}
