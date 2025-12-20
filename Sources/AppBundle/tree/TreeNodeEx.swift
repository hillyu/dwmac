import AppKit
import Common

extension TreeNode {
    private func visit(node: TreeNode, result: inout [Window]) {
        if let node = node as? Window {
            result.append(node)
        }
        for child in node.children {
            visit(node: child, result: &result)
        }
    }
    var allLeafWindowsRecursive: [Window] {
        var result: [Window] = []
        visit(node: self, result: &result)
        return result
    }

    var ownIndex: Int? {
        guard let parent else { return nil }
        return parent.children.firstIndex(of: self).orDie()
    }

    var parents: [NonLeafTreeNodeObject] { parent.flatMap { [$0] + $0.parents } ?? [] }
    var parentsWithSelf: [TreeNode] { parent.flatMap { [self] + $0.parentsWithSelf } ?? [self] }

    /// Also see visualWorkspace
    var nodeWorkspace: Workspace? {
        self as? Workspace ?? parent?.nodeWorkspace
    }

    /// Also see: workspace
    @MainActor
    var visualWorkspace: Workspace? { nodeWorkspace ?? nodeMonitor?.activeWorkspace }

    @MainActor
    var nodeMonitor: Monitor? {
        switch self.nodeCases {
            case .workspace(let ws): ws.workspaceMonitor
            case .window: parent?.nodeMonitor
            // case .tilingContainer: parent?.nodeMonitor
            case .macosFullscreenWindowsContainer: parent?.nodeMonitor
            case .macosHiddenAppsWindowsContainer: parent?.nodeMonitor
            case .macosMinimizedWindowsContainer, .macosPopupWindowsContainer: nil
        }
    }

    var mostRecentWindowRecursive: Window? {
        self as? Window ?? mostRecentChild?.mostRecentWindowRecursive
    }

    var anyLeafWindowRecursive: Window? {
        if let window = self as? Window {
            return window
        }
        for child in children {
            if let window = child.anyLeafWindowRecursive {
                return window
            }
        }
        return nil
    }

    // Doesn't contain at least one window
    var isEffectivelyEmpty: Bool {
        anyLeafWindowRecursive == nil
    }

    @MainActor
    var hWeight: CGFloat {
        get { getWeight(.h) }
        set { setWeight(.h, newValue) }
    }

    @MainActor
    var vWeight: CGFloat {
        get { getWeight(.v) }
        set { setWeight(.v, newValue) }
    }

    /// Returns closest parent that has children in the specified direction relative to `self`
    /// In flat structure, this is simplified.
    func closestParent(
        hasChildrenInDirection direction: CardinalDirection,
        withLayout layout: Layout?,
    ) -> (parent: Workspace, ownIndex: Int)? {
        guard let window = self as? Window else { return nil }
        guard let workspace = window.nodeWorkspace else { return nil }

        if let layout, workspace.layout != layout { return nil }
        if workspace.orientation != direction.orientation { return nil }

        // In simple list, we check if next/prev index exists?
        // Wait, closestParent logic was about finding a split container in the tree.
        // Now there is only one container: Workspace.

        // So we just check if moving in that direction is valid in the list?
        // But FocusCommand logic used this to find *where* to move.

        // Let's assume this returns the Workspace if the direction implies movement in the list.
        // For Master-Stack (assuming H orientation):
        // Left/Right = Prev/Next?

        // Actually, let's just return the workspace if it matches criteria.
        guard let index = window.ownIndex else { return nil }
        let nextIndex = index + direction.focusOffset
        if workspace.children.indices.contains(nextIndex) {
            return (workspace, index)
        }
        return nil
    }
}
