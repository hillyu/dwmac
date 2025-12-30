@testable import AppBundle
import XCTest

@MainActor
final class CenterFloatingWindowsTest: XCTestCase {
    func testParseCenterFloatingWindows() {
        let (config, errors) = parseConfig(
            """
            center-floating-windows = true
            """,
        )
        assertEquals(errors, [])
        XCTAssertTrue(config.centerFloatingWindows)
    }

    func testParseCenterFloatingWindowsDefault() {
        let (config, errors) = parseConfig("")
        assertEquals(errors, [])
        XCTAssertFalse(config.centerFloatingWindows)
    }
}
