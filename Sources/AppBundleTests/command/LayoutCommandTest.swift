@testable import AppBundle
import Common
import XCTest

final class LayoutCommandTest: XCTestCase {
    @MainActor
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testParseCommand() {
        testParseCommandSucc("layout master-stack", LayoutCmdArgs(rawArgs: [], toggleBetween: [.master_stack]))
        testParseCommandSucc("layout h_master-stack", LayoutCmdArgs(rawArgs: [], toggleBetween: [.h_master_stack]))
        testParseCommandSucc("layout v_master-stack", LayoutCmdArgs(rawArgs: [], toggleBetween: [.v_master_stack]))
        testParseCommandSucc("layout tiling floating", LayoutCmdArgs(rawArgs: [], toggleBetween: [.tiling, .floating]))

        testParseCommandFail("layout foo", msg: """
            ERROR: Can't parse 'foo'
                   Possible values: (master-stack|horizontal|vertical|h_master-stack|v_master-stack|tiling|floating)
            """)
    }

    @MainActor
    func testFloatingTilingToggle() async throws {
        let workspace = Workspace.get(byName: "a")
        let window = TestWindow.new(id: 1, parent: workspace).apply { _ = $0.focusWindow() }

        // Initial state should be tiling
        XCTAssertFalse(window.isFloating)

        // Toggle to floating
        try await LayoutCommand(args: LayoutCmdArgs(rawArgs: [], toggleBetween: [.tiling, .floating]))
            .run(.defaultEnv, .emptyStdin)
        XCTAssertTrue(window.isFloating)

        // Toggle back to tiling
        try await LayoutCommand(args: LayoutCmdArgs(rawArgs: [], toggleBetween: [.tiling, .floating]))
            .run(.defaultEnv, .emptyStdin)
        XCTAssertFalse(window.isFloating)
    }
}
