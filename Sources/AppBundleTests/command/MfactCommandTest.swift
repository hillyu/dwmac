@testable import AppBundle
import Common
import XCTest

@MainActor
final class MfactCommandTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testMfactSet() async throws {
        let workspace = Workspace.get(byName: name).apply {
            $0.layout = .masterStack
            _ = TestWindow.new(id: 1, parent: $0).focusWindow()
            TestWindow.new(id: 2, parent: $0)
        }

        var args = MfactCmdArgs(rawArgs: [])
        args.amount = .initialized(.set(0.7))
        try await MfactCommand(args: args).run(.defaultEnv, .emptyStdin)
        XCTAssertEqual(workspace.mfact, 0.7, accuracy: 0.001)
    }

    func testMfactAdd() async throws {
        let workspace = Workspace.get(byName: name).apply {
            $0.layout = .masterStack
            _ = TestWindow.new(id: 1, parent: $0).focusWindow()
        }

        var args = MfactCmdArgs(rawArgs: [])
        args.amount = .initialized(.add(0.1))
        try await MfactCommand(args: args).run(.defaultEnv, .emptyStdin)
        XCTAssertEqual(workspace.mfact, 0.6, accuracy: 0.001) // 0.5 + 0.1
    }

    func testMfactSubtract() async throws {
        let workspace = Workspace.get(byName: name).apply {
            $0.layout = .masterStack
            _ = TestWindow.new(id: 1, parent: $0).focusWindow()
        }

        var args = MfactCmdArgs(rawArgs: [])
        args.amount = .initialized(.subtract(0.1))
        try await MfactCommand(args: args).run(.defaultEnv, .emptyStdin)
        XCTAssertEqual(workspace.mfact, 0.4, accuracy: 0.001) // 0.5 - 0.1
    }

    func testMfactClamp() async throws {
        let workspace = Workspace.get(byName: name).apply {
            $0.layout = .masterStack
            _ = TestWindow.new(id: 1, parent: $0).focusWindow()
        }

        var args = MfactCmdArgs(rawArgs: [])
        args.amount = .initialized(.set(1.5))
        try await MfactCommand(args: args).run(.defaultEnv, .emptyStdin)
        XCTAssertEqual(workspace.mfact, 0.95, accuracy: 0.001)

        args = MfactCmdArgs(rawArgs: [])
        args.amount = .initialized(.set(-0.5))
        try await MfactCommand(args: args).run(.defaultEnv, .emptyStdin)
        XCTAssertEqual(workspace.mfact, 0.05, accuracy: 0.001)
    }
}
