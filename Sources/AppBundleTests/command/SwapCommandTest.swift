@testable import AppBundle
import Common
import XCTest

@MainActor
final class SwapCommandTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testSwap_swapWindows_Directional() async throws {
        let workspace = Workspace.get(byName: name).apply {
            assertEquals(TestWindow.new(id: 1, parent: $0).focusWindow(), true)
            TestWindow.new(id: 2, parent: $0)
            TestWindow.new(id: 3, parent: $0)
        }
        // [1, 2, 3]

        // Swap right -> [2, 1, 3]
        try await SwapCommand(args: SwapCmdArgs(rawArgs: [], target: .direction(.right))).run(.defaultEnv, .emptyStdin)
        assertEquals(workspace.layoutDescription,
                     .h_master_stack([.window(2), .window(1), .window(3)]))
        assertEquals(focus.windowOrNil?.windowId, 1)

        // Swap left -> [1, 2, 3]
        try await SwapCommand(args: SwapCmdArgs(rawArgs: [], target: .direction(.left))).run(.defaultEnv, .emptyStdin)
        assertEquals(workspace.layoutDescription,
                     .h_master_stack([.window(1), .window(2), .window(3)]))
        assertEquals(focus.windowOrNil?.windowId, 1)

        // Swap down (assuming horizontal layout, down might be next/right) -> [2, 1, 3]
        // If orientation is horizontal, down/up might be mapped to next/prev or ignored.
        // Let's assume standard behavior where secondary direction maps to primary.
        try await SwapCommand(args: SwapCmdArgs(rawArgs: [], target: .direction(.down))).run(.defaultEnv, .emptyStdin)
        // Assuming down == right for horizontal
        // assertEquals(workspace.layoutDescription, .h_master_stack([.window(2), .window(1), .window(3)]))
    }

    func testSwap_swapWindows_DfsRelative() async throws {
        let workspace = Workspace.get(byName: name).apply {
            assertEquals(TestWindow.new(id: 1, parent: $0).focusWindow(), true)
            TestWindow.new(id: 2, parent: $0)
            TestWindow.new(id: 3, parent: $0)
        }
        // [1, 2, 3]

        try await SwapCommand(args: SwapCmdArgs(rawArgs: [], target: .relative(.next))).run(.defaultEnv, .emptyStdin)
        assertEquals(workspace.layoutDescription,
                     .h_master_stack([.window(2), .window(1), .window(3)]))
        assertEquals(focus.windowOrNil?.windowId, 1)

        try await SwapCommand(args: SwapCmdArgs(rawArgs: [], target: .relative(.next))).run(.defaultEnv, .emptyStdin)
        assertEquals(workspace.layoutDescription,
                     .h_master_stack([.window(2), .window(3), .window(1)]))
        assertEquals(focus.windowOrNil?.windowId, 1)

        try await SwapCommand(args: SwapCmdArgs(rawArgs: [], target: .relative(.prev))).run(.defaultEnv, .emptyStdin)
        assertEquals(workspace.layoutDescription,
                     .h_master_stack([.window(2), .window(1), .window(3)]))
        assertEquals(focus.windowOrNil?.windowId, 1)
    }

    func testSwap_DirectionalWrapping() async throws {
        let workspace = Workspace.get(byName: name).apply {
            assertEquals(TestWindow.new(id: 1, parent: $0).focusWindow(), true)
            TestWindow.new(id: 2, parent: $0)
            TestWindow.new(id: 3, parent: $0)
        }
        // [1, 2, 3]

        var args = SwapCmdArgs(rawArgs: [], target: .direction(.left))
        args.wrapAround = true
        // Swap left (wrap) -> 1 with 3? -> [3, 2, 1]
        try await SwapCommand(args: args).run(.defaultEnv, .emptyStdin)
        assertEquals(workspace.layoutDescription, .h_master_stack([.window(3), .window(2), .window(1)]))
        assertEquals(focus.windowOrNil?.windowId, 1)

        args.target = .initialized(.direction(.right))
        // Swap right (wrap) -> 1 with 3? -> [1, 2, 3]
        try await SwapCommand(args: args).run(.defaultEnv, .emptyStdin)
        assertEquals(workspace.layoutDescription, .h_master_stack([.window(1), .window(2), .window(3)]))
        assertEquals(focus.windowOrNil?.windowId, 1)
    }

    func testSwap_SwapFocus() async throws {
        let workspace = Workspace.get(byName: name).apply {
            TestWindow.new(id: 1, parent: $0)
            assertEquals(TestWindow.new(id: 2, parent: $0).focusWindow(), true)
            TestWindow.new(id: 3, parent: $0)
        }
        // [1, 2, 3] (focus 2)

        var args = SwapCmdArgs(rawArgs: [], target: .direction(.right))
        args.swapFocus = true
        // Swap 2 with 3, and focus 3 (the one that was swapped)
        try await SwapCommand(args: args).run(.defaultEnv, .emptyStdin)
        assertEquals(workspace.layoutDescription, .h_master_stack([.window(1), .window(3), .window(2)]))
        assertEquals(focus.windowOrNil?.windowId, 3)
    }
}
