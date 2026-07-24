import Foundation

/// Soustraction protégée pour un compteur cumulatif (octets réseau/disque
/// depuis le boot, etc.) qui peut diminuer d'un tick à l'autre (interface
/// réseau qui disparaît, disque externe débranché) plutôt que seulement
/// augmenter. Une soustraction wrapping (`&-`) dans ce cas produirait une
/// valeur proche de `UInt64.max` — bug déjà rencontré une fois sur le réseau
/// (cf. `CHANGES.md`) et évité depuis dans `NetworkMonitor`/`DiskMonitor`.
enum SafeDelta {
    static func of(_ current: UInt64, since previous: UInt64) -> UInt64 {
        current >= previous ? current - previous : 0
    }
}
