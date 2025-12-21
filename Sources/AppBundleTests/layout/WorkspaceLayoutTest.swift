@testable import AppBundle
import XCTest

@MainActor
final class WorkspaceLayoutTest: XCTestCase {
    override func setUp() async throws {
        setUpWorkspacesForTests()
    }

    func testLayoutMasterStackWithInnerGaps() async throws {
        // Setup config with inner gaps
        config.gaps = Gaps(
            inner: .init(vertical: 10, horizontal: 10),
            outer: .zero,
        )

        let workspace = Workspace.get(byName: "test")
        workspace.layout = .masterStack
        workspace.orientation = .h

        // Add 2 windows with initial rects
        let initialRect = Rect(topLeftX: 0, topLeftY: 0, width: 100, height: 100)
        let w1 = TestWindow.new(id: 1, parent: workspace, rect: initialRect)
        let w2 = TestWindow.new(id: 2, parent: workspace, rect: initialRect)

        // Layout
        try await workspace.layoutWorkspace()

        // Monitor is 1920x1080. Outer gaps 0.
        // Available width = 1920. Available height = 1080 (passed as 1079 in layoutWorkspace)
        // Master width = (1920 - 10) * 0.5 = 955.
        // Master height = 1079.

        // Note: Floating point comparisons might require accuracy, but using Integers here
        XCTAssertEqual(w1.lastAppliedLayoutPhysicalRect?.width, 955)
        XCTAssertEqual(w1.lastAppliedLayoutPhysicalRect?.height, 1079)
        XCTAssertEqual(w1.lastAppliedLayoutPhysicalRect?.topLeftX, 0)
        XCTAssertEqual(w1.lastAppliedLayoutPhysicalRect?.topLeftY, 0)

        // Stack X = 955 + 10 = 965.
        XCTAssertEqual(w2.lastAppliedLayoutPhysicalRect?.topLeftX, 965)
        XCTAssertEqual(w2.lastAppliedLayoutPhysicalRect?.width, 955)
        XCTAssertEqual(w2.lastAppliedLayoutPhysicalRect?.height, 1079)
    }

    func testLayoutMasterStackWithInnerGaps_Vertical() async throws {
        config.gaps = Gaps(
            inner: .init(vertical: 10, horizontal: 10),
            outer: .zero,
        )
        let workspace = Workspace.get(byName: "testV")
        workspace.layout = .masterStack
        workspace.orientation = .v

        let initialRect = Rect(topLeftX: 0, topLeftY: 0, width: 100, height: 100)
        let w1 = TestWindow.new(id: 1, parent: workspace, rect: initialRect)
        let w2 = TestWindow.new(id: 2, parent: workspace, rect: initialRect)

        try await workspace.layoutWorkspace()

        // Master Height = (1079 - 10) * 0.5 = 1069 * 0.5 = 534.5
        // Master Width = 1920

        XCTAssertEqual(w1.lastAppliedLayoutPhysicalRect?.width, 1920)
        XCTAssertEqual(w1.lastAppliedLayoutPhysicalRect?.height, 534.5)

        // Stack Y = 534.5 + 10 = 544.5
        // Stack Height = 534.5
        XCTAssertEqual(w2.lastAppliedLayoutPhysicalRect?.topLeftY, 544.5)
        XCTAssertEqual(w2.lastAppliedLayoutPhysicalRect?.height, 534.5)
    }
}
