import WidgetKit
import SwiftUI

/// Entrée de timeline : l'instantané publié par l'app, ou la raison précise de
/// son absence.
struct SnapshotEntry: TimelineEntry {
    let date: Date
    let result: WidgetSnapshotStore.ReadResult

    var snapshot: WidgetSnapshot? {
        if case .available(let snapshot) = result { return snapshot }
        return nil
    }
}

/// Fournisseur commun aux quatre widgets : ils affichent tous des facettes du
/// même instantané, seule la vue change.
struct SnapshotProvider: TimelineProvider {
    /// Cadence demandée au système. WidgetKit reste libre de l'espacer selon le
    /// budget — c'est une intention, pas une garantie, d'où l'horodatage affiché
    /// par les widgets.
    private static let refreshInterval: TimeInterval = 5 * 60

    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: Date(), result: .available(.placeholder))
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        // En galerie de widgets, l'app n'a peut-être jamais tourné : montrer des
        // valeurs d'exemple plutôt qu'un état vide, sinon le widget paraît cassé
        // au moment précis où l'utilisateur choisit de l'ajouter.
        let result = WidgetSnapshotStore.read()
        let displayed: WidgetSnapshotStore.ReadResult
        if case .available = result {
            displayed = result
        } else if context.isPreview {
            displayed = .available(.placeholder)
        } else {
            displayed = result
        }
        completion(SnapshotEntry(date: Date(), result: displayed))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let entry = SnapshotEntry(date: Date(), result: WidgetSnapshotStore.read())
        let next = Date().addingTimeInterval(Self.refreshInterval)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

extension WidgetSnapshot {
    /// Valeurs d'exemple pour la galerie et les previews. Volontairement
    /// plausibles plutôt que rondes, pour donner une idée juste du rendu.
    static let placeholder = WidgetSnapshot(
        capturedAt: Date(),
        cpu: .init(
            totalPercent: 23.4,
            userPercent: 16.1,
            systemPercent: 7.3,
            history: (0..<30).map { 18 + 12 * sin(Double($0) / 4) },
            topProcessName: "Xcode",
            topProcessPercent: 42.7
        ),
        memory: .init(
            usedPercent: 61.2,
            usedBytes: 10_500_000_000,
            totalBytes: 17_179_869_184,
            history: (0..<30).map { 55 + 8 * cos(Double($0) / 5) },
            topProcessName: "Safari",
            topProcessBytes: 1_900_000_000
        ),
        battery: .init(
            percentage: 76,
            isCharging: false,
            healthPercent: 98,
            cycleCount: 42,
            timeRemainingMinutes: 284,
            celsius: 31.4
        ),
        sensors: .init(
            available: true,
            hasFans: false,
            maxCelsius: 48.2,
            maxLabel: "CPU",
            readings: [
                .init(label: "CPU", celsius: 48.2),
                .init(label: "GPU", celsius: 44.6),
                .init(label: "Airport", celsius: 39.1),
                .init(label: "NAND", celsius: 36.8),
            ],
            fanRPMs: []
        )
    )
}
