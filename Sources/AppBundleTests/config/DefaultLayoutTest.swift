@testable import AppBundle
import Common
import XCTest

@MainActor
final class DefaultLayoutTest: XCTestCase {
    func testParseDefaultLayout() {
        let (config, errors) = parseConfig(
            """
            default-root-container-layout = 'master-stack'
            """,
        )
        XCTAssertEqual(errors, [])
        XCTAssertEqual(config.defaultRootContainerLayout, .masterStack)
    }

    func testParseDefaultLayoutInvalid() {
        let (_, errors) = parseConfig(
            """
            default-root-container-layout = 'invalid'
            """,
        )
        XCTAssertEqual(errors.descriptions, ["default-root-container-layout: Can't parse layout 'invalid'"])
    }
}
