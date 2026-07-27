import XCTest
@testable import MacInside

/// `WidgetSnapshot` est le contrat sérialisé entre l'app et l'extension widget,
/// deux process signés séparément : une rupture d'encodage ne se verrait pas à
/// la compilation, seulement par un widget qui cesse silencieusement de se
/// mettre à jour. D'où ces tests de round-trip.
final class WidgetSnapshotTests: XCTestCase {
    private func roundTrip(_ snapshot: WidgetSnapshot) throws -> WidgetSnapshot {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(WidgetSnapshot.self, from: encoder.encode(snapshot))
    }

    func testRoundTripPreservesValues() throws {
        let original = WidgetSnapshot(
            capturedAt: Date(timeIntervalSince1970: 1_800_000_000),
            cpu: .init(totalPercent: 42.5, userPercent: 30, systemPercent: 12.5,
                       history: [1, 2, 3], topProcessName: "Xcode", topProcessPercent: 88.25),
            memory: .init(usedPercent: 61, usedBytes: 10_000_000_000,
                          totalBytes: 17_179_869_184, history: [50, 55],
                          topProcessName: "Safari", topProcessBytes: 1_500_000_000),
            battery: .init(percentage: 76, isCharging: true, healthPercent: 98,
                           cycleCount: 42, timeRemainingMinutes: 120, celsius: 31.5),
            sensors: .init(available: true, hasFans: true, maxCelsius: 48.2, maxLabel: "CPU",
                           readings: [.init(label: "CPU", celsius: 48.2)], fanRPMs: [1200, 1300])
        )

        XCTAssertEqual(try roundTrip(original), original)
    }

    /// Un Mac de bureau n'a pas de batterie : `nil` doit rester `nil` et ne pas
    /// se décoder en une struct à zéro, sinon le widget afficherait « 0 % »
    /// au lieu de « Pas de batterie sur ce Mac ».
    func testAbsentBatteryStaysNil() throws {
        var snapshot = WidgetSnapshot.placeholderForTests
        snapshot.battery = nil
        XCTAssertNil(try roundTrip(snapshot).battery)
    }

    /// Même distinction pour l'autonomie : macOS ne fournit pas toujours
    /// d'estimation (`pmset -g batt` → « no estimate »).
    func testAbsentTimeRemainingStaysNil() throws {
        var snapshot = WidgetSnapshot.placeholderForTests
        snapshot.battery?.timeRemainingMinutes = nil
        XCTAssertNil(try roundTrip(snapshot).battery?.timeRemainingMinutes)
    }

    func testDateSurvivesRoundTripToTheSecond() throws {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        var snapshot = WidgetSnapshot.placeholderForTests
        snapshot.capturedAt = date
        // ISO8601 ne transporte pas les fractions de seconde : comparer à la
        // seconde près plutôt qu'à l'identique.
        XCTAssertEqual(try roundTrip(snapshot).capturedAt.timeIntervalSince1970,
                       date.timeIntervalSince1970, accuracy: 1)
    }
}

private extension WidgetSnapshot {
    /// Équivalent local du `placeholder` de l'extension, qui n'est pas compilé
    /// dans la cible de test (elle ne dépend que de l'app).
    static var placeholderForTests: WidgetSnapshot {
        WidgetSnapshot(
            capturedAt: Date(timeIntervalSince1970: 1_800_000_000),
            cpu: .init(totalPercent: 20, userPercent: 15, systemPercent: 5,
                       history: [10, 20], topProcessName: nil, topProcessPercent: nil),
            memory: .init(usedPercent: 50, usedBytes: 8_000_000_000,
                          totalBytes: 16_000_000_000, history: [40, 50],
                          topProcessName: nil, topProcessBytes: nil),
            battery: .init(percentage: 50, isCharging: false, healthPercent: 100,
                           cycleCount: 10, timeRemainingMinutes: 60, celsius: nil),
            sensors: .init(available: true, hasFans: false, maxCelsius: 40, maxLabel: "CPU",
                           readings: [], fanRPMs: [])
        )
    }
}
