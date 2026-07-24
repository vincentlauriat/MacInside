import Foundation

/// Batteries des accessoires Bluetooth connectés (AirPods, Magic Mouse/
/// Keyboard/Trackpad...), via `system_profiler SPBluetoothDataType -json`.
///
/// Pas de lecture IOKit directe possible ici, contrairement à GPU/disque :
/// vérifié empiriquement (`ioreg -l | grep -i batter`) que les AirPods
/// n'apparaissent dans aucun service du registre IOKit (seule la batterie
/// interne du Mac, `AppleSmartBattery`, y figure). `IOBluetoothDevice`
/// (API privée, `batteryPercent*` via KVC) a aussi été testée : `isConnected()`
/// renvoie `false` pour un accessoire pourtant connecté quand le process n'a
/// pas l'entitlement/la permission Bluetooth d'une app signée — pas fiable
/// depuis un script isolé, et un chemin fragile à committer sans pouvoir le
/// re-tester facilement. `system_profiler` est la source déjà utilisée par les
/// Réglages Bluetooth système et couvre tous les types d'accessoires
/// (écouteurs et périphériques HID) avec un seul format.
final class AccessoryBatteryMonitor {
    private var cached: [AccessoryBatteryReading] = []
    private var lastFetch: Date?
    private let refreshInterval: TimeInterval = 30

    func snapshot() -> AccessoryBatteryStats {
        refreshIfNeeded()
        return AccessoryBatteryStats(accessories: cached)
    }

    private func refreshIfNeeded() {
        let now = Date()
        if let lastFetch, now.timeIntervalSince(lastFetch) < refreshInterval { return }
        lastFetch = now
        cached = Self.fetchConnectedAccessoryBatteries()
    }

    private static func fetchConnectedAccessoryBatteries() -> [AccessoryBatteryReading] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["-json", "SPBluetoothDataType"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return parse(data)
        } catch {
            return []
        }
    }

    /// Extrait toute clé `device_batteryLevel*` plutôt que de figer une liste
    /// de suffixes devinée (`device_batteryLevel` seul pour un accessoire HID
    /// simple type Magic Mouse, `...Left`/`...Right`/`...Case` pour des
    /// AirPods — suffixes vérifiés empiriquement sur de vrais AirPods
    /// connectés, pas garantis identiques pour tous les modèles). Dédupliqué
    /// par nom d'appareil : un même accessoire (AirPods) peut apparaître deux
    /// fois sous des adresses différentes (adresse BLE tournante vs adresse
    /// réelle), constaté sur cette machine de test.
    private static func parse(_ data: Data) -> [AccessoryBatteryReading] {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let entries = json["SPBluetoothDataType"] as? [[String: Any]]
        else { return [] }

        var readings: [AccessoryBatteryReading] = []
        var seenNames = Set<String>()

        for entry in entries {
            guard let connected = entry["device_connected"] as? [[String: Any]] else { continue }
            for deviceEntry in connected {
                for (name, rawInfo) in deviceEntry {
                    guard seenNames.insert(name).inserted, let info = rawInfo as? [String: Any] else { continue }
                    for (key, value) in info where key.hasPrefix("device_batteryLevel") {
                        guard let percent = percent(from: value) else { continue }
                        let part = String(key.dropFirst("device_batteryLevel".count))
                        readings.append(AccessoryBatteryReading(name: name, part: part, percent: percent))
                    }
                }
            }
        }
        return readings
    }

    private static func percent(from value: Any) -> Int? {
        guard let text = value as? String else { return nil }
        let digits = text.unicodeScalars.filter(CharacterSet.decimalDigits.contains)
        return Int(String(String.UnicodeScalarView(digits)))
    }
}
