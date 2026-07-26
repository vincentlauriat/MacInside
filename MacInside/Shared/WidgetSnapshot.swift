import Foundation

/// Instantané des métriques écrit par l'app dans le conteneur App Group et relu
/// par l'extension widget.
///
/// L'extension est **obligatoirement sandboxée** (contrainte macOS sur les app
/// extensions) alors que l'app ne l'est pas : le widget ne peut donc pas lire le
/// SMC, IOKit ou `system_profiler` lui-même. Tout ce qu'il affiche transite par
/// cette struct.
///
/// Conséquence de conception : les libellés arrivent **déjà localisés**, générés
/// côté app à partir de `Localizable.xcstrings`. Dupliquer le catalogue dans
/// l'extension aurait fait diverger les deux traductions à la première retouche.
struct WidgetSnapshot: Codable, Equatable {
    /// Date de capture, affichée par les widgets : les données WidgetKit ont
    /// plusieurs minutes d'âge par construction, autant que ce soit visible
    /// plutôt que de laisser croire à du temps réel.
    var capturedAt: Date

    var cpu: CPU
    var memory: Memory
    /// `nil` sur une machine sans batterie (Mac mini, Studio…), cas distinct
    /// d'une batterie à 0 %.
    var battery: Battery?
    var sensors: Sensors

    struct CPU: Codable, Equatable {
        var totalPercent: Double
        var userPercent: Double
        var systemPercent: Double
        /// Historique de charge le plus récent, borné à `historyLimit`.
        var history: [Double]
        var topProcessName: String?
        var topProcessPercent: Double?
    }

    struct Memory: Codable, Equatable {
        var usedPercent: Double
        var usedBytes: UInt64
        var totalBytes: UInt64
        var history: [Double]
        var topProcessName: String?
        var topProcessBytes: Double?
    }

    struct Battery: Codable, Equatable {
        var percentage: Int
        var isCharging: Bool
        var healthPercent: Int
        var cycleCount: Int
        var timeRemainingMinutes: Int?
        /// Température de la batterie si un capteur SMC la remonte, sinon `nil`.
        var celsius: Double?
    }

    struct Sensors: Codable, Equatable {
        var available: Bool
        var hasFans: Bool
        /// Température maximale hors capteurs « Battery » (déjà exposés par
        /// `Battery.celsius`), cohérent avec l'agrégat du dashboard.
        var maxCelsius: Double?
        var maxLabel: String?
        /// Quelques capteurs les plus chauds, libellés déjà localisés.
        var readings: [Reading]
        var fanRPMs: [Int]

        struct Reading: Codable, Equatable {
            var label: String
            var celsius: Double
        }
    }

    /// Les widgets n'affichent qu'une sparkline courte : transporter les 60
    /// échantillons du dashboard gonflerait le fichier sans rien apporter.
    static let historyLimit = 30
    /// Nombre de capteurs embarqués dans l'instantané (les plus chauds).
    static let sensorLimit = 4
}
