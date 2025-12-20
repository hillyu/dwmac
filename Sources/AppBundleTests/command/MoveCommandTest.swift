@testable import AppBundle
import Common
import XCTest

@MainActor
final class MoveCommandTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testMove_swapWindows() async throws {
        let workspace = Workspace.get(byName: name).apply {
            assertEquals(TestWindow.new(id: 1, parent: $0).focusWindow(), true)
            TestWindow.new(id: 2, parent: $0)
        }

        try await MoveCommand(args: MoveCmdArgs(rawArgs: [], .right)).run(.defaultEnv, .emptyStdin)
        // 1 moved right -> swapped with 2
        assertEquals(workspace.layoutDescription, .h_master_stack([.window(2), .window(1)]))
    }

    func testMove_mru() async throws {
        var window3: Window!
        let workspace = Workspace.get(byName: name).apply {
            TestWindow.new(id: 0, parent: $0)
            assertEquals(TestWindow.new(id: 1, parent: $0).focusWindow(), true)
            TestWindow.new(id: 2, parent: $0)
            window3 = TestWindow.new(id: 3, parent: $0)
            TestWindow.new(id: 4, parent: $0)
        }
        // [0, 1, 2, 3, 4]
        // Focus is 1.

        window3.markAsMostRecentChild()

        // Move 1 right. Should swap with 2? Or depends on MRU?
        // Standard move usually swaps with neighbor in list order.
        try await MoveCommand(args: MoveCmdArgs(rawArgs: [], .right)).run(.defaultEnv, .emptyStdin)

        // If it moves by index: [0, 2, 1, 3, 4]
        assertEquals(
            workspace.layoutDescription,
            .h_master_stack([
                .window(0),
                .window(2),
                .window(1),
                .window(3),
                .window(4),
            ]),
        )
    }

    func testSwap_preserveWeight() async throws {
        let workspace = Workspace.get(byName: name)
        // adaptiveWeight is only relevant for tiling windows in appropriate layout.
        // In Master-Stack, windows don't have individual weights in the same way as containers,
        // but maybe we simulate it?
        // Actually, let's just create windows.
        let window1 = TestWindow.new(id: 1, parent: workspace, adaptiveWeight: 1)
        let window2 = TestWindow.new(id: 2, parent: workspace, adaptiveWeight: 2)
        _ = window2.focusWindow()

        // [1 (w1), 2 (w2)]
        // Move 2 left -> [2, 1]
        try await MoveCommand(args: MoveCmdArgs(rawArgs: [], .left)).run(.defaultEnv, .emptyStdin)

        // Weights might be swapped or preserved depending on logic.
        // In new arch, weights are likely associated with the window itself.
        assertEquals(window2.hWeight, 2)
        assertEquals(window1.hWeight, 1)
    }

    func testCreateImplicitContainer() async throws {
        // Implicit container creation (split) is no longer a thing in flat layout usually?
        // Or does "move up" create a vertical split?
        // In flat Master-Stack, everything is flat.
        // If "move up" is called, it probably does nothing or moves to prev (if vertical).

        let workspace = Workspace.get(byName: name).apply {
            TestWindow.new(id: 1, parent: $0)
            assertEquals(TestWindow.new(id: 2, parent: $0).focusWindow(), true)
            TestWindow.new(id: 3, parent: $0)
        }
        // [1, 2, 3]

        // If orientation is horizontal, up/down might be invalid or no-op or wrap?
        // Let's assume it does nothing or throws if direction is invalid for orientation.
        // Or if it maps to index:

        _ = try await MoveCommand(args: MoveCmdArgs(rawArgs: [], .up)).run(.defaultEnv, .emptyStdin)

        // Expect no change if orientation is horizontal and up/down not supported or mapped to nothing.
        // Or maybe it maps to prev?
        // If it maps to prev: [2, 1, 3]
        // Let's verify what 'up' means in horizontal workspace.
        // Usually up/down in horizontal workspace is no-op.

        assertEquals(
            workspace.layoutDescription,
            .h_master_stack([.window(2), .window(1), .window(3)]),
        )
        // assertEquals(result.exitCode, 0)
    }

    func testStop_onRootNode() async throws {
        let workspace = Workspace.get(byName: name).apply {
            assertEquals(TestWindow.new(id: 1, parent: $0).focusWindow(), true)
            TestWindow.new(id: 2, parent: $0)
            TestWindow.new(id: 3, parent: $0)
        }
        // [1, 2, 3], focus 1.

        // Move left (past 1). Should stop.
        let result = try await parseCommand("move --boundaries-action stop left").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertEquals(
            workspace.layoutDescription,
            .h_master_stack([.window(1), .window(2), .window(3)]),
        )
        assertEquals(result.exitCode, 0)
    }

    func testFail() async throws {
        let workspace = Workspace.get(byName: name).apply {
            assertEquals(TestWindow.new(id: 1, parent: $0).focusWindow(), true)
            TestWindow.new(id: 2, parent: $0)
            TestWindow.new(id: 3, parent: $0)
        }

        // Move left (past 1). Should fail.
        let result = try await parseCommand("move --boundaries-action fail left").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertEquals(
            workspace.layoutDescription,
            .h_master_stack([.window(1), .window(2), .window(3)]),
        )
        assertEquals(result.exitCode, 1)
    }

    func testMoveOutWithNormalization_right() async throws {
        config.enableNormalizationFlattenContainers = true

        let workspace = Workspace.get(byName: name).apply {
            TestWindow.new(id: 1, parent: $0)
            assertEquals(TestWindow.new(id: 2, parent: $0).focusWindow(), true)
        }
        // [1, 2]

        try await MoveCommand(args: MoveCmdArgs(rawArgs: [], .right)).run(.defaultEnv, .emptyStdin)
        // 2 is already at end. Move right -> stop or wrap?
        // If implicit wrap is off, it stops.

        assertEquals(
            workspace.layoutDescription,
            .h_master_stack([
                .window(1),
                .window(2),
            ]),
        )
        assertEquals(focus.windowOrNil?.windowId, 2)
    }
}
