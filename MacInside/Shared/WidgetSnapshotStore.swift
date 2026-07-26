import Foundation

/// Passe-plat entre l'app (qui écrit) et l'extension widget (qui lit), via le
/// conteneur App Group partagé.
///
/// Un simple fichier JSON plutôt que `UserDefaults(suiteName:)` : l'instantané
/// contient des tableaux d'historique, et un fichier écrit atomiquement se prête
/// mieux à une lecture concurrente depuis un autre process qu'un plist
/// `UserDefaults` mis à jour à chaque tick.
enum WidgetSnapshotStore {
    /// Doit rester identique dans les entitlements de l'app **et** de
    /// l'extension. Le préfixe Team ID est imposé par macOS.
    static let appGroupIdentifier = "KFLACS69T9.fr.vincentlauriat.macinside"

    private static let fileName = "widget-snapshot.json"

    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent(fileName)
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// Écrit l'instantané. Retourne `false` si le conteneur est inaccessible ou
    /// l'écriture échoue — l'appelant décide quoi en faire ; côté app, un échec
    /// ne doit jamais interrompre la boucle de rafraîchissement du dashboard.
    @discardableResult
    static func write(_ snapshot: WidgetSnapshot) -> Bool {
        guard let fileURL else { return false }
        do {
            let data = try encoder.encode(snapshot)
            // `.atomic` : le widget peut lire à n'importe quel moment, il ne
            // doit jamais tomber sur un fichier à moitié écrit.
            try data.write(to: fileURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    /// Relit l'instantané, ou `nil` si l'app ne l'a encore jamais écrit (widget
    /// ajouté avant le premier lancement, par exemple) — cas que les widgets
    /// doivent afficher explicitement plutôt que de montrer des zéros.
    static func read() -> WidgetSnapshot? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }
}
