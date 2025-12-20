@testable import AppBundle
import Common
import XCTest

@MainActor
final class FocusCommandMasterStackTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testFocusNextPrevInMasterStack() async throws {
        let workspace = Workspace.get(byName: name)
        var master: Window!

        workspace.rootTilingContainer.apply {
            // master-stack layout
            $0.layout = .masterStack
            master = TestWindow.new(id: 1, parent: $0)
            TestWindow.new(id: 2, parent: $0) // stack1
            TestWindow.new(id: 3, parent: $0) // stack2
        }

        // Initial focus on master
        _ = master.focusWindow()
        assertEquals(focus.windowOrNil?.windowId, 1)

        // focus dfs-next -> stack1
        try await FocusCommand.new(dfsRelative: .dfsNext).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 2)

        // focus dfs-next -> stack2
        try await FocusCommand.new(dfsRelative: .dfsNext).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 3)

        // focus dfs-prev -> stack1
        try await FocusCommand.new(dfsRelative: .dfsPrev).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 2)

        // focus dfs-prev -> master
        try await FocusCommand.new(dfsRelative: .dfsPrev).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 1)

        // Test aliases next/prev
        // focus next -> stack1
        try await FocusCommand.new(dfsRelative: .dfsNext).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 2)

        // focus prev -> master
        try await FocusCommand.new(dfsRelative: .dfsPrev).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 1)
    }

    func testFocusNextPrevWrappingInMasterStack() async throws {
        let workspace = Workspace.get(byName: name)
        workspace.rootTilingContainer.apply {
            $0.layout = .masterStack
            TestWindow.new(id: 1, parent: $0) // Master
            TestWindow.new(id: 2, parent: $0) // Stack 1
            TestWindow.new(id: 3, parent: $0) // Stack 2
        }

        // Focus stack2 (last)
        _ = Window.get(byId: 3)?.focusWindow()
        assertEquals(focus.windowOrNil?.windowId, 3)

        // focus dfs-next with wrapping -> master
        var args = FocusCmdArgs(rawArgs: [], cardinalOrDfsDirection: .dfsRelative(.dfsNext))
        args.rawBoundaries = .workspace
        args.rawBoundariesAction = .wrapAroundTheWorkspace

        try await FocusCommand(args: args).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 1)

        // focus dfs-prev with wrapping -> stack2
        args.cardinalOrDfsDirection = .dfsRelative(.dfsPrev)
        try await FocusCommand(args: args).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 3)
    }

    func testFocusNextPrevImplicitWrapping() async throws {
        let workspace = Workspace.get(byName: name)
        workspace.rootTilingContainer.apply {
            $0.layout = .masterStack
            TestWindow.new(id: 1, parent: $0) // Master
            TestWindow.new(id: 2, parent: $0) // Stack 1
            TestWindow.new(id: 3, parent: $0) // Stack 2
        }

        // Focus stack2 (last)
        _ = Window.get(byId: 3)?.focusWindow()

        // focus next (implicit wrapping) -> master
        try await FocusCommand.new(dfsRelative: .dfsNext).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 1)

        // focus prev (implicit wrapping) -> stack2
        try await FocusCommand.new(dfsRelative: .dfsPrev).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 3)
    }
}
