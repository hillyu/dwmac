@testable import AppBundle
import Common
import XCTest

@MainActor
final class FocusCommandTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testParse() {
        XCTAssertTrue(parseCommand("focus --boundaries left").errorOrNil?.contains("Possible values") == true)
        var expected = FocusCmdArgs(rawArgs: ["--boundaries", "workspace", "next"].slice, nextPrev: .next)
        expected.rawBoundaries = .workspace
        testParseCommandSucc("focus --boundaries workspace next", expected)

        assertEquals(
            parseCommand("focus --boundaries workspace --boundaries workspace next").errorOrNil,
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

    func testFocusRelative() async throws {
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

        var args = FocusCmdArgs(rawArgs: [], nextPrev: .next)
        args.rawBoundariesAction = .wrapAroundTheWorkspace
        try await FocusCommand(args: args).run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 1) // Wrap around
    }

    func testFocusRelativeWrapping() async throws {
        Workspace.get(byName: name).apply {
            assertEquals(TestWindow.new(id: 1, parent: $0).focusWindow(), true)
            TestWindow.new(id: 2, parent: $0)
        }

        assertEquals(focus.windowOrNil?.windowId, 1)

        var args = FocusCmdArgs(rawArgs: [], nextPrev: .prev)

        args.rawBoundariesAction = .stop
        assertEquals(try await FocusCommand(args: args).run(.defaultEnv, .emptyStdin).exitCode, 0)
        assertEquals(focus.windowOrNil?.windowId, 1)

        args.rawBoundariesAction = .fail
        assertEquals(try await FocusCommand(args: args).run(.defaultEnv, .emptyStdin).exitCode, 1)
        assertEquals(focus.windowOrNil?.windowId, 1)

        args.rawBoundariesAction = .wrapAroundTheWorkspace
        assertEquals(try await FocusCommand(args: args).run(.defaultEnv, .emptyStdin).exitCode, 0)
        assertEquals(focus.windowOrNil?.windowId, 2)

        args.nextPrev = .next

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
    static func new(relative: NextPrev) -> FocusCommand {
        FocusCommand(args: FocusCmdArgs(rawArgs: [], nextPrev: relative))
    }
}
