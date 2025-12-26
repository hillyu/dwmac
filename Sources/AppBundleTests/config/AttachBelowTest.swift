import XCTest
import Common
@testable import AppBundle

final class AttachBelowTest: XCTestCase {
    @MainActor
    func testAttachBelowTrue() {
        let configStr = """
            attach-below = true
            """
        let (parsedConfig, errors) = parseConfig(configStr)
        XCTAssertTrue(errors.isEmpty)
        XCTAssertTrue(parsedConfig.attachBelow)
    }

    @MainActor
    func testAttachBelowFalse() {
        let configStr = """
            attach-below = false
            """
        let (parsedConfig, errors) = parseConfig(configStr)
        XCTAssertTrue(errors.isEmpty)
        XCTAssertFalse(parsedConfig.attachBelow)
    }

    @MainActor
    func testAttachBelowDefault() {
        let configStr = ""
        let (parsedConfig, errors) = parseConfig(configStr)
        XCTAssertTrue(errors.isEmpty)
        XCTAssertFalse(parsedConfig.attachBelow)
    }
}
