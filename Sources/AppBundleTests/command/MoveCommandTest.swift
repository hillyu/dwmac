@testable import AppBundle
import Common
import XCTest

@MainActor
final class MoveCommandTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testMoveFloating() async throws {
        let workspace = Workspace.get(byName: name)
        let window = TestWindow.new(id: 1, parent: workspace, rect: Rect(topLeftX: 100, topLeftY: 100, width: 200, height: 200))
        window.bindAsFloatingWindow(to: workspace)
        _ = window.focusWindow()

        // Move right
        try await MoveCommand(args: MoveCmdArgs(rawArgs: [], .right)).run(.defaultEnv, .emptyStdin)

        // Expected: x += 50 -> 150
        var rect = try await window.getAxRect()
        assertEquals(rect?.topLeftCorner.x, 150)
        assertEquals(rect?.topLeftCorner.y, 100)

        // Move down
        try await MoveCommand(args: MoveCmdArgs(rawArgs: [], .down)).run(.defaultEnv, .emptyStdin)

        rect = try await window.getAxRect()
        assertEquals(rect?.topLeftCorner.x, 150)
        assertEquals(rect?.topLeftCorner.y, 150)
    }

    func testMoveTilingFails() async throws {
        let workspace = Workspace.get(byName: name)
        let window = TestWindow.new(id: 1, parent: workspace)
        _ = window.focusWindow()
        // Window is tiling by default (bound to workspace)

        let result = try await MoveCommand(args: MoveCmdArgs(rawArgs: [], .right)).run(.defaultEnv, .emptyStdin)
        assertEquals(result.exitCode, 1)
    }
}
