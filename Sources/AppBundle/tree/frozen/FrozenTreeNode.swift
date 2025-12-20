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
    let weight: CGFloat

    @MainActor init(_ workspace: Workspace) {
        children = workspace.tilingWindows.map { .window(FrozenWindow($0)) }
        layout = workspace.layout
        orientation = workspace.orientation
        weight = 1 // Workspace has no weight
    }
}

struct FrozenWindow: Sendable {
    let id: UInt32
    let weight: CGFloat

    @MainActor init(_ window: Window) {
        id = window.windowId
        weight = getWeightOrNil(window) ?? 1
    }
}

@MainActor private func getWeightOrNil(_ node: TreeNode) -> CGFloat? {
    guard let workspace = node.parent as? Workspace else { return nil }
    switch getChildParentRelation(child: node, parent: workspace) {
        case .tiling: return node.getWeight(workspace.orientation)
        default: return nil
    }
}
