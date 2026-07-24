import XCTest
@testable import MacInside

final class FormattersTests: XCTestCase {
    func testUptimeFormatsHoursMinutesSeconds() {
        XCTAssertEqual(Formatters.uptime(3661), "01:01:01")
        XCTAssertEqual(Formatters.uptime(0), "00:00:00")
        XCTAssertEqual(Formatters.uptime(59), "00:00:59")
    }

    func testMinutesFormatsHoursAndMinutes() {
        XCTAssertEqual(Formatters.minutes(90), "1 h 30 min")
        XCTAssertEqual(Formatters.minutes(45), "45 min")
        XCTAssertEqual(Formatters.minutes(0), "0 min")
    }

    func testPercentIncludesValueAndSign() {
        XCTAssertEqual(Formatters.percent(42), "42%")
        // Le séparateur décimal est sensible à la locale (",": FR, ".": EN) —
        // on vérifie la présence des chiffres plutôt qu'une chaîne exacte.
        let withDecimal = Formatters.percent(42.5, decimals: 1)
        XCTAssertTrue(withDecimal.contains("42"))
        XCTAssertTrue(withDecimal.contains("5"))
        XCTAssertTrue(withDecimal.hasSuffix("%"))
    }

    func testCelsiusIncludesUnit() {
        let result = Formatters.celsius(20)
        XCTAssertTrue(result.contains("20"))
        XCTAssertTrue(result.contains("°C"))
    }

    func testBytesPerSecondAppendsSuffix() {
        XCTAssertTrue(Formatters.bytesPerSecond(1024).hasSuffix("/s"))
        // Une valeur négative (ne devrait jamais arriver en pratique, delta protégé
        // par SafeDelta) ne doit pas crasher la conversion Double -> UInt64.
        XCTAssertTrue(Formatters.bytesPerSecond(-5).hasSuffix("/s"))
    }
}
