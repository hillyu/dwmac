@testable import AppBundle
import Common
import XCTest

@MainActor
final class MoveNodeToMasterTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testMoveNodeToMaster() async throws {
        let workspace = Workspace.get(byName: name)
        workspace.rootTilingContainer.apply {
            $0.layout = .masterStack
            TestWindow.new(id: 1, parent: $0) // Master (0)
            TestWindow.new(id: 2, parent: $0) // Stack 1 (1)
            TestWindow.new(id: 3, parent: $0) // Stack 2 (2)
        }

        // Focus Stack 1 (id 2)
        _ = Window.get(byId: 2)?.focusWindow()

        // Run command
        try await MoveNodeToMasterCommand(args: MoveNodeToMasterCmdArgs(rawArgs: [])).run(.defaultEnv, .emptyStdin)

        // Check order
        let children = workspace.rootTilingContainer.children
        XCTAssertEqual((children[0] as? Window)?.windowId, 2) // New Master
        XCTAssertEqual((children[1] as? Window)?.windowId, 1) // Old Master pushed down
        XCTAssertEqual((children[2] as? Window)?.windowId, 3) // Stack 2 stays
    }

    func testMoveNodeToMaster_AlreadyMaster() async throws {
        let workspace = Workspace.get(byName: name)
        workspace.rootTilingContainer.apply {
            $0.layout = .masterStack
            TestWindow.new(id: 1, parent: $0) // Master
            TestWindow.new(id: 2, parent: $0) // Stack 1
        }

        _ = Window.get(byId: 1)?.focusWindow()

        try await MoveNodeToMasterCommand(args: MoveNodeToMasterCmdArgs(rawArgs: [])).run(.defaultEnv, .emptyStdin)

        let children = workspace.rootTilingContainer.children
        XCTAssertEqual((children[0] as? Window)?.windowId, 1)
        XCTAssertEqual((children[1] as? Window)?.windowId, 2)
    }
}
