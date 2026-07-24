import XCTest
@testable import MacInside

final class SafeDeltaTests: XCTestCase {
    func testNormalIncrease() {
        XCTAssertEqual(SafeDelta.of(150, since: 100), 50)
    }

    func testEqualValuesYieldZero() {
        XCTAssertEqual(SafeDelta.of(100, since: 100), 0)
    }

    /// Cas réel ayant déjà fait planter l'app (cf. CHANGES.md) : un compteur
    /// cumulé qui régresse (interface réseau qui disparaît, disque externe
    /// débranché) ne doit jamais produire un delta wrappé proche de UInt64.max.
    func testCounterRegressionYieldsZeroNotWraparound() {
        XCTAssertEqual(SafeDelta.of(50, since: 100), 0)
        XCTAssertEqual(SafeDelta.of(0, since: UInt64.max), 0)
    }

    func testLargeValuesDoNotOverflow() {
        XCTAssertEqual(SafeDelta.of(UInt64.max, since: 0), UInt64.max)
    }
}
