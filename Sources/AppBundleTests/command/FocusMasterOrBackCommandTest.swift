@testable import AppBundle
import Common
import XCTest

@MainActor
final class FocusMasterOrBackCommandTest: XCTestCase {
    override func setUp() async throws {
        setUpWorkspacesForTests()
    }

    func testFocusMasterOrBack() async throws {
        let workspace = Workspace.get(byName: "test")
        // Master window (id 1)
        let master = TestWindow.new(id: 1, parent: workspace)
        // Window B (id 2)
        let windowB = TestWindow.new(id: 2, parent: workspace)
        // Window C (id 3)
        let windowC = TestWindow.new(id: 3, parent: workspace)

        // Focus B
        _ = windowB.focusWindow()
        XCTAssertEqual(focus.windowOrNil, windowB)

        // Command: Focus Master
        _ = try await FocusMasterOrBackCommand(args: FocusMasterOrBackCmdArgs(rawArgs: [] as StrArrSlice)).run(.defaultEnv, CmdIo(stdin: .emptyStdin))
        XCTAssertEqual(focus.windowOrNil, master)

        // Command: Back
        _ = try await FocusMasterOrBackCommand(args: FocusMasterOrBackCmdArgs(rawArgs: [] as StrArrSlice)).run(.defaultEnv, CmdIo(stdin: .emptyStdin))
        XCTAssertEqual(focus.windowOrNil, windowB)

        // Focus C
        _ = windowC.focusWindow()

        // Command: Focus Master
        _ = try await FocusMasterOrBackCommand(args: FocusMasterOrBackCmdArgs(rawArgs: [] as StrArrSlice)).run(.defaultEnv, CmdIo(stdin: .emptyStdin))
        XCTAssertEqual(focus.windowOrNil, master)

        // Command: Back
        _ = try await FocusMasterOrBackCommand(args: FocusMasterOrBackCmdArgs(rawArgs: [] as StrArrSlice)).run(.defaultEnv, CmdIo(stdin: .emptyStdin))
        XCTAssertEqual(focus.windowOrNil, windowC)
    }

    func testFocusMasterOrBack_NoHistory() async throws {
        let workspace = Workspace.get(byName: "test")
        let master = TestWindow.new(id: 1, parent: workspace)
        _ = TestWindow.new(id: 2, parent: workspace) // windowB

        // Focus Master manually
        _ = master.focusWindow()
        XCTAssertEqual(focus.windowOrNil, master)

        // Command: Back (Should fail or do nothing as no history set by this command)
        let res = try await FocusMasterOrBackCommand(args: FocusMasterOrBackCmdArgs(rawArgs: [] as StrArrSlice)).run(.defaultEnv, CmdIo(stdin: .emptyStdin))
        XCTAssertFalse(res)
        XCTAssertEqual(focus.windowOrNil, master)
    }
}
