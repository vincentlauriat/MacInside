import Foundation

/// Températures et ventilateurs via le client SMC (`AppleSMC`, IOKit).
/// La connexion SMC est ouverte une seule fois à l'initialisation et
/// conservée pour toute la durée de vie du monitor — `snapshot()` ne fait
/// que des lectures de clés, pas de réouverture. Les clés de température
/// varient énormément d'un modèle à l'autre (Intel vs Apple Silicon, et même
/// entre générations de puce) : on essaie une liste de clés candidates et on
/// ignore silencieusement celles qui ne répondent pas ou renvoient une
/// valeur hors plage plausible, plutôt que de viser l'exhaustivité.
final class SensorMonitor {
    private let client = SMCClient()

    func snapshot() -> SensorStats {
        guard client.isOpen else { return SensorStats(available: false) }

        let temperatures = Self.readTemperatures(client)
        let fanCount = Self.readFanCount(client)
        let fans = Self.readFans(client, count: fanCount ?? 0)
        let power = Self.readPower(client)
        let hasFans = fanCount != nil

        guard !temperatures.isEmpty || hasFans else {
            return SensorStats(available: false)
        }
        return SensorStats(available: true, hasFans: hasFans, temperatures: temperatures, fans: fans, power: power)
    }

    /// Présence de la clé `FNum` : distingue "ce Mac n'a pas de ventilateur"
    /// (Mac Studio/mini fanless) de "la lecture a échoué" — `readFans` seul ne
    /// permet pas de faire la différence puisqu'il renvoie `[]` dans les deux cas.
    private static func readFanCount(_ client: SMCClient) -> Int? {
        guard let (countBytes, countType) = client.read("FNum"),
              let countValue = SMCClient.decodeValue(bytes: countBytes, dataType: countType)
        else { return nil }
        return Int(countValue)
    }

    private static func readTemperatures(_ client: SMCClient) -> [SensorReading] {
        temperatureKeys.compactMap { key, label in
            guard let (bytes, dataType) = client.read(key),
                  let celsius = SMCClient.decodeValue(bytes: bytes, dataType: dataType),
                  celsius > 0, celsius < 120
            else { return nil }
            return SensorReading(key: key, label: label, celsius: celsius)
        }
    }

    private static func readFans(_ client: SMCClient, count: Int) -> [FanReading] {
        guard count > 0, count <= 10 else { return [] }

        return (0..<count).compactMap { index -> FanReading? in
            guard let (rpmBytes, rpmType) = client.read("F\(index)Ac"),
                  let rpm = SMCClient.decodeValue(bytes: rpmBytes, dataType: rpmType)
            else { return nil }

            let minRpm = client.read("F\(index)Mn")
                .flatMap { SMCClient.decodeValue(bytes: $0.bytes, dataType: $0.dataType) } ?? 0
            let maxRpm = client.read("F\(index)Mx")
                .flatMap { SMCClient.decodeValue(bytes: $0.bytes, dataType: $0.dataType) } ?? 0

            return FanReading(
                id: index,
                label: fanLabel(client, index: index),
                rpm: Int(rpm.rounded()),
                minRpm: Int(minRpm.rounded()),
                maxRpm: Int(maxRpm.rounded())
            )
        }
    }

    private static func readPower(_ client: SMCClient) -> [PowerReading] {
        powerKeys.compactMap { key, label, unit in
            guard let (bytes, dataType) = client.read(key),
                  let value = SMCClient.decodeValue(bytes: bytes, dataType: dataType),
                  value > 0
            else { return nil }
            return PowerReading(key: key, label: label, value: value, unit: unit)
        }
    }

    private static func fanLabel(_ client: SMCClient, index: Int) -> String {
        if let (bytes, _) = client.read("F\(index)ID") {
            let printable = bytes.filter { $0 >= 0x20 && $0 < 0x7F }
            if let name = String(bytes: printable, encoding: .ascii)?
                .trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
                return name
            }
        }
        return "Ventilateur \(index + 1)"
    }

    /// Clés de température candidates avec libellé lisible. Liste non
    /// exhaustive par construction (voir note en tête de fichier) — couvre
    /// les clés les plus courantes documentées par la communauté (Stats app,
    /// smcFanControl, macs-fan-control) pour Intel et Apple Silicon.
    private static let temperatureKeys: [(key: String, label: String)] = [
        // Intel
        ("TC0P", "CPU Proximity"), ("TC0D", "CPU Die"), ("TC0E", "CPU"), ("TC0F", "CPU"),
        ("TC1C", "CPU Core 1"), ("TC2C", "CPU Core 2"), ("TC3C", "CPU Core 3"), ("TC4C", "CPU Core 4"),
        ("TC5C", "CPU Core 5"), ("TC6C", "CPU Core 6"), ("TC7C", "CPU Core 7"), ("TC8C", "CPU Core 8"),
        ("TCGC", "GPU Intégré"), ("TG0P", "GPU Proximity"), ("TG0D", "GPU Die"),
        ("TM0P", "Mémoire"), ("TM0S", "Mémoire"),
        ("TA0P", "Ambiante"), ("TA1P", "Ambiante 2"),
        ("Ts0S", "Repose-poignet"), ("TB0T", "Batterie"), ("TW0P", "AirPort"),
        ("TN0D", "Northbridge Die"), ("TN0P", "Northbridge Proximity"),
        // Apple Silicon
        ("Tp01", "CPU Performance Core 1"), ("Tp05", "CPU Performance Core 2"),
        ("Tp09", "CPU Performance Core 3"), ("Tp0D", "CPU Performance Core 4"),
        ("Tp0H", "CPU Performance Core 5"), ("Tp0L", "CPU Performance Core 6"),
        ("Tp0P", "CPU Performance Core 7"), ("Tp0T", "CPU Performance Core 8"),
        ("Tp0X", "CPU Performance"),
        ("Te05", "CPU Efficiency Core 1"), ("Te0L", "CPU Efficiency Core 2"),
        ("Te0P", "CPU Efficiency Core 3"), ("Te0S", "CPU Efficiency Core 4"),
        ("Tg05", "GPU 1"), ("Tg0D", "GPU 2"), ("Tg0E", "GPU 3"), ("Tg0F", "GPU 4"),
        ("Tg0H", "GPU 5"), ("Tg0L", "GPU 6"), ("Tg0P", "GPU 7"), ("Tg0T", "GPU 8"), ("Tg0X", "GPU"),
        ("TaLP", "Ambiante"), ("TaLC", "Ambiante 2"),
        ("Ts0P", "Batterie"), ("Ts1P", "Batterie 2"),
    ]

    /// Clés de tension/courant/puissance candidates (alimentation secteur).
    /// Même logique défensive que les températures : liste non exhaustive,
    /// clés absentes ignorées silencieusement.
    private static let powerKeys: [(key: String, label: String, unit: String)] = [
        ("VD0R", "DC In", "V"), ("ID0R", "DC In", "A"), ("PDTR", "DC In", "W"),
        ("PSTR", "Système", "W"), ("PPBR", "Batterie", "W"),
    ]
}
