@testable import AppBundle
import Common
import XCTest

final class ResizeCommandTest: XCTestCase {
    func testParseCommand() {
        testParseCommandSucc("resize smart +10", ResizeCmdArgs(rawArgs: [], dimension: .smart, units: .add(10)))
        testParseCommandSucc("resize smart -10", ResizeCmdArgs(rawArgs: [], dimension: .smart, units: .subtract(10)))
        testParseCommandSucc("resize smart 10", ResizeCmdArgs(rawArgs: [], dimension: .smart, units: .set(10)))

        testParseCommandSucc("resize smart-opposite +10", ResizeCmdArgs(rawArgs: [], dimension: .smartOpposite, units: .add(10)))
        testParseCommandSucc("resize smart-opposite -10", ResizeCmdArgs(rawArgs: [], dimension: .smartOpposite, units: .subtract(10)))
        testParseCommandSucc("resize smart-opposite 10", ResizeCmdArgs(rawArgs: [], dimension: .smartOpposite, units: .set(10)))

        testParseCommandSucc("resize height 10", ResizeCmdArgs(rawArgs: [], dimension: .height, units: .set(10)))
        testParseCommandSucc("resize width 10", ResizeCmdArgs(rawArgs: [], dimension: .width, units: .set(10)))

        testParseCommandSucc("resize smart +0.5", ResizeCmdArgs(rawArgs: [], dimension: .smart, units: .add(0.5)))
        testParseCommandSucc("resize smart -0.5", ResizeCmdArgs(rawArgs: [], dimension: .smart, units: .subtract(0.5)))

        testParseCommandFail("resize s 10", msg: """
            ERROR: Can't parse 's'.
                   Possible values: (width|height|smart|smart-opposite)
            """)
        testParseCommandFail("resize smart foo", msg: "ERROR: <number> argument must be a number")
    }

    @MainActor
    func testResizeFloating() async throws {
        setUpWorkspacesForTests()
        let workspace = Workspace.get(byName: "testResizeFloating")
        let window = TestWindow.new(id: 1, parent: workspace, rect: Rect(topLeftX: 100, topLeftY: 100, width: 200, height: 200))
        window.bindAsFloatingWindow(to: workspace)
        _ = window.focusWindow()

        // Resize width +50
        try await ResizeCommand(args: ResizeCmdArgs(rawArgs: [], dimension: .width, units: .add(50))).run(.defaultEnv, .emptyStdin)

        var rect = try await window.getAxRect()
        assertEquals(rect?.width, 250)
        assertEquals(rect?.height, 200)

        // Resize height set 300
        try await ResizeCommand(args: ResizeCmdArgs(rawArgs: [], dimension: .height, units: .set(300))).run(.defaultEnv, .emptyStdin)

        rect = try await window.getAxRect()
        assertEquals(rect?.width, 250)
        assertEquals(rect?.height, 300)
    }

    @MainActor
    func testResizeTilingFails() async throws {
        setUpWorkspacesForTests()
        let workspace = Workspace.get(byName: "testResizeTilingFails")
        let window = TestWindow.new(id: 1, parent: workspace)
        _ = window.focusWindow()

        let result = try await ResizeCommand(args: ResizeCmdArgs(rawArgs: [], dimension: .width, units: .add(50))).run(.defaultEnv, .emptyStdin)
        assertEquals(result.exitCode, 1)
    }
}
