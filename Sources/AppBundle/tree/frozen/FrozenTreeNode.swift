import AppKit
import Common

enum FrozenTreeNode: Sendable {
    case container(FrozenContainer) // Kept for compatibility but effectively represents Workspace root
    case window(FrozenWindow)
}

struct FrozenContainer: Sendable {
    let children: [FrozenTreeNode]
    let layout: Layout
    let orientation: Orientation

    @MainActor init(_ workspace: Workspace) {
        children = workspace.tilingWindows.map { .window(FrozenWindow($0)) }
        layout = workspace.layout
        orientation = workspace.orientation
    }
}

struct FrozenWindow: Sendable {
    let id: UInt32

    @MainActor init(_ window: Window) {
        id = window.windowId
    }
}
