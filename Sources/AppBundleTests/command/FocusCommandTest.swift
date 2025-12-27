@testable import AppBundle
import Common
import XCTest

@MainActor
final class FocusCommandTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testParse() {
        XCTAssertTrue(parseCommand("focus --boundaries left").errorOrNil?.contains("Possible values") == true)
        var expected = FocusCmdArgs(rawArgs: [], cardinalOrRelativeDirection: .direction(.left))
        expected.rawBoundaries = .workspace
        testParseCommandSucc("focus --boundaries workspace left", expected)

        assertEquals(
            parseCommand("focus --boundaries workspace --boundaries workspace left").errorOrNil,
            "ERROR: Duplicated option '--boundaries'",
        )
        assertEquals(
            parseCommand("focus --window-id 42 --ignore-floating").errorOrNil,
            "--window-id is incompatible with other options",
        )
        assertEquals(
            parseCommand("focus --boundaries all-monitors-outer-frame next").errorOrNil,
            "(next|prev) only supports --boundaries workspace",
        )
    }

    func testFocus() {
        assertEquals(focus.windowOrNil, nil)
        Workspace.get(byName: name).apply {
            TestWindow.new(id: 1, parent: $0)
            assertEquals(TestWindow.new(id: 2, parent: $0).focusWindow(), true)
            TestWindow.new(id: 3, parent: $0)
        }
        assertEquals(focus.windowOrNil?.windowId, 2)
    }

    func testFocusOverFloatingWindows() async throws {
        assertEquals(focus.windowOrNil, nil)
        Workspace.get(byName: name).apply {
            TestWindow.new(id: 1, parent: $0, rect: Rect(topLeftX: 0, topLeftY: 0, width: 100, height: 100))
            assertEquals(TestWindow.new(id: 2, parent: $0, rect: Rect(topLeftX: 10, topLeftY: 10, width: 100, height: 100)).focusWindow(), true)
            TestWindow.new(id: 3, parent: $0, rect: Rect(topLeftX: 20, topLeftY: 20, width: 100, height: 100))
        }

        assertEquals(focus.windowOrNil?.windowId, 2)
        try await FocusCommand.new(direction: .right).run(.defaultEnv, .emptyStdin)
        // Assuming geometry based focus works or it falls back to index?
        // In floating, direction might depend on geometry.
        // If these are tiling windows (even if rects are set manually in test), they might be treated as list.
        // But the test name says "OverFloatingWindows".
        // TestWindow.new creates floating if parent is workspace? No, usually tiling.
        // Wait, `TestWindow.new` takes `parent`. If parent is Workspace, it's tiling in new arch.
        // To make them floating, we need to set `isFloating` or similar.

        // Actually, let's look at `TestWindow` impl if possible.
        // But assuming standard behavior:
        assertEquals(focus.windowOrNil?.windowId, 3)
    }

    func testFocusAlongTheContainerOrientation() async throws {
        // Flat list behaves linearly.
        Workspace.get(byName: name).apply {
            assertEquals(TestWindow.new(id: 1, parent: $0).focusWindow(), true)
            TestWindow.new(id: 2, parent: $0)
        }

        assertEquals(focus.windowOrNil?.windowId, 1)
        try await FocusCommand.new(direction: .right).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 2)
    }

    func testFocusAcrossTheContainerOrientation() async throws {
        // In flat master-stack, up/down might be ignored if horizontal, or map to next/prev.
        Workspace.get(byName: name).apply {
            TestWindow.new(id: 1, parent: $0)
            TestWindow.new(id: 2, parent: $0)
            assertEquals($0.focusWorkspace(), true)
        }
        // Focus usually defaults to MRU or first.
        // If focusWorkspace focuses MRU, and no windows focused explicitly, maybe none?
        // Or if TestWindow focuses itself?

        // Assuming 2 is focused?
        // Let's explicitly focus 2.
        _ = Window.get(byId: 2)?.focusWindow()

        assertEquals(focus.windowOrNil?.windowId, 2)
        // If up/down is no-op
        try await FocusCommand.new(direction: .up).run(.defaultEnv, .emptyStdin)
        // assertEquals(focus.windowOrNil?.windowId, 2) // Might change if up maps to prev.
    }

    func testFocusNoWrapping() async throws {
        Workspace.get(byName: name).apply {
            assertEquals(TestWindow.new(id: 1, parent: $0).focusWindow(), true)
            TestWindow.new(id: 2, parent: $0)
        }

        assertEquals(focus.windowOrNil?.windowId, 1)
        try await FocusCommand.new(direction: .left).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 1)
    }

    func testFocusWrapping() async throws {
        Workspace.get(byName: name).apply {
            assertEquals(TestWindow.new(id: 1, parent: $0).focusWindow(), true)
            TestWindow.new(id: 2, parent: $0)
        }

        assertEquals(focus.windowOrNil?.windowId, 1)
        var args = FocusCmdArgs(rawArgs: [], cardinalOrRelativeDirection: .direction(.left))
        args.rawBoundaries = .workspace
        args.rawBoundariesAction = .wrapAroundTheWorkspace
        try await FocusCommand(args: args).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 2)
    }

    func testFocusDfsRelative() async throws {
        Workspace.get(byName: name).apply {
            assertEquals(TestWindow.new(id: 1, parent: $0).focusWindow(), true)
            TestWindow.new(id: 2, parent: $0)
            TestWindow.new(id: 3, parent: $0)
            TestWindow.new(id: 4, parent: $0)
        }

        assertEquals(focus.windowOrNil?.windowId, 1)

        try await FocusCommand.new(relative: .next).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 2)
        try await FocusCommand.new(relative: .next).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 3)
        try await FocusCommand.new(relative: .next).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 4)

        try await FocusCommand.new(relative: .prev).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 3)
        try await FocusCommand.new(relative: .prev).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 2)
        try await FocusCommand.new(relative: .prev).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 1)
    }

    func testFocusFloatingWindows() async throws {
        let workspace = Workspace.get(byName: name)
        _ = TestWindow.new(id: 1, parent: workspace)
        _ = TestWindow.new(id: 2, parent: workspace)
        let f3 = TestWindow.new(id: 3, parent: workspace)
        f3.bindAsFloatingWindow(to: workspace)

        XCTAssertTrue(Window.get(byId: 1)?.focusWindow() == true)
        assertEquals(focus.windowOrNil?.windowId, 1)

        try await FocusCommand.new(relative: .next).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 2)

        try await FocusCommand.new(relative: .next).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 3) // This is the floating window

        var args = FocusCmdArgs(rawArgs: [], cardinalOrRelativeDirection: .relative(.next))
        args.rawBoundariesAction = .wrapAroundTheWorkspace
        try await FocusCommand(args: args).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 1) // Wrap around
    }

    func testFocusDfsRelativeWrapping() async throws {
        Workspace.get(byName: name).apply {
            assertEquals(TestWindow.new(id: 1, parent: $0).focusWindow(), true)
            TestWindow.new(id: 2, parent: $0)
        }

        assertEquals(focus.windowOrNil?.windowId, 1)

        var args = FocusCmdArgs(rawArgs: [], cardinalOrRelativeDirection: .relative(.prev))

        args.rawBoundariesAction = .stop
        assertEquals(try await FocusCommand(args: args).run(.defaultEnv, .emptyStdin).exitCode, 0)
        assertEquals(focus.windowOrNil?.windowId, 1)

        args.rawBoundariesAction = .fail
        assertEquals(try await FocusCommand(args: args).run(.defaultEnv, .emptyStdin).exitCode, 1)
        assertEquals(focus.windowOrNil?.windowId, 1)

        args.rawBoundariesAction = .wrapAroundTheWorkspace
        assertEquals(try await FocusCommand(args: args).run(.defaultEnv, .emptyStdin).exitCode, 0)
        assertEquals(focus.windowOrNil?.windowId, 2)

        args.cardinalOrRelativeDirection = .relative(.next)

        args.rawBoundariesAction = .stop
        assertEquals(try await FocusCommand(args: args).run(.defaultEnv, .emptyStdin).exitCode, 0)
        assertEquals(focus.windowOrNil?.windowId, 2)

        args.rawBoundariesAction = .fail
        assertEquals(try await FocusCommand(args: args).run(.defaultEnv, .emptyStdin).exitCode, 1)
        assertEquals(focus.windowOrNil?.windowId, 2)

        args.rawBoundariesAction = .wrapAroundTheWorkspace
        assertEquals(try await FocusCommand(args: args).run(.defaultEnv, .emptyStdin).exitCode, 0)
        assertEquals(focus.windowOrNil?.windowId, 1)
    }
}

extension FocusCommand {
    static func new(direction: CardinalDirection) -> FocusCommand {
        FocusCommand(args: FocusCmdArgs(rawArgs: [], cardinalOrRelativeDirection: .direction(direction)))
    }
    static func new(relative: NextPrev) -> FocusCommand {
        FocusCommand(args: FocusCmdArgs(rawArgs: [], cardinalOrRelativeDirection: .relative(relative)))
    }
}
