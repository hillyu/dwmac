import AppKit
import Common

/// First line of defence against lock screen
@MainActor private var closedWindowsCache = FrozenWorld(workspaces: [], monitors: [], windowIds: [])

struct FrozenMonitor: Sendable {
    let topLeftCorner: CGPoint
    let visibleWorkspace: String

    @MainActor init(_ monitor: Monitor) {
        topLeftCorner = monitor.rect.topLeftCorner
        visibleWorkspace = monitor.activeWorkspace.name
    }
}

struct FrozenWorkspace: Sendable {
    let name: String
    let monitor: FrozenMonitor
    let rootTilingNode: FrozenContainer // Represents Workspace state
    let floatingWindows: [FrozenWindow]
    let macosUnconventionalWindows: [FrozenWindow]

    @MainActor init(_ workspace: Workspace) {
        name = workspace.name
        monitor = FrozenMonitor(workspace.workspaceMonitor)
        rootTilingNode = FrozenContainer(workspace)
        floatingWindows = workspace.floatingWindows.map(FrozenWindow.init)
        macosUnconventionalWindows =
            workspace.macOsNativeHiddenAppsWindowsContainer.children.map { FrozenWindow($0 as! Window) } +
            workspace.macOsNativeFullscreenWindowsContainer.children.map { FrozenWindow($0 as! Window) }
    }
}

@MainActor func cacheClosedWindowIfNeeded() {
    let allWs = Workspace.all
    let allWindowIds = allWs.flatMap { collectAllWindowIds(workspace: $0) }.toSet()
    if allWindowIds.isSubset(of: closedWindowsCache.windowIds) {
        return // already cached
    }
    closedWindowsCache = FrozenWorld(
        workspaces: allWs.map { FrozenWorkspace($0) },
        monitors: monitors.map(FrozenMonitor.init),
        windowIds: allWindowIds,
    )
}

@MainActor func restoreClosedWindowsCacheIfNeeded(newlyDetectedWindow: Window) async throws -> Bool {
    if !closedWindowsCache.windowIds.contains(newlyDetectedWindow.windowId) {
        return false
    }
    let monitors = monitors
    let topLeftCornerToMonitor = monitors.grouped { $0.rect.topLeftCorner }

    for frozenWorkspace in closedWindowsCache.workspaces {
        let workspace = Workspace.get(byName: frozenWorkspace.name)
        _ = topLeftCornerToMonitor[frozenWorkspace.monitor.topLeftCorner]?
            .singleOrNil()?
            .setActiveWorkspace(workspace)
        for frozenWindow in frozenWorkspace.floatingWindows {
            MacWindow.get(byId: frozenWindow.id)?.bindAsFloatingWindow(to: workspace)
        }
        for frozenWindow in frozenWorkspace.macosUnconventionalWindows {
            MacWindow.get(byId: frozenWindow.id)?.bindAsFloatingWindow(to: workspace)
        }

        let potentialOrphans = workspace.tilingWindows

        // Restore layout properties
        workspace.layout = frozenWorkspace.rootTilingNode.layout
        workspace.orientation = frozenWorkspace.rootTilingNode.orientation

        // Restore Tiling Windows
        for (index, child) in frozenWorkspace.rootTilingNode.children.enumerated() {
            switch child {
                case .window(let w):
                    guard let window = MacWindow.get(byId: w.id) else { continue }
                    window.bind(to: workspace, adaptiveWeight: w.weight, index: index)
                case .container:
                    die("Containers not supported in restoration")
            }
        }

        // Relayout orphans (windows that were tiling but not in cache? or vice versa?)
        // If bind happened above, they are already in correct place.
        // We just need to check if any were left out.
        let newTiling = workspace.tilingWindows.map { $0.windowId }.toSet()

        for orphan in potentialOrphans.filter({ !newTiling.contains($0.windowId) }) {
            try await orphan.relayoutWindow(on: workspace, forceTile: true)
        }
    }

    for monitor in closedWindowsCache.monitors {
        _ = topLeftCornerToMonitor[monitor.topLeftCorner]?
            .singleOrNil()?
            .setActiveWorkspace(Workspace.get(byName: monitor.visibleWorkspace))
    }
    return true
}

@MainActor func resetClosedWindowsCache() {
    closedWindowsCache = FrozenWorld(workspaces: [], monitors: [], windowIds: [])
}
