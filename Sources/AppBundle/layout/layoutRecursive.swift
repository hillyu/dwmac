import AppKit

extension Workspace {
    @MainActor
    func layoutWorkspace() async throws {
        if isEffectivelyEmpty { return }
        let rect = workspaceMonitor.visibleRectPaddedByOuterGaps
        try await layoutRecursive(rect.topLeftCorner, width: rect.width, height: rect.height - 1, virtual: rect, LayoutContext(self))
    }
}

extension TreeNode {
    @MainActor
    fileprivate func layoutRecursive(_ point: CGPoint, width: CGFloat, height: CGFloat, virtual: Rect, _ context: LayoutContext) async throws {
        let physicalRect = Rect(topLeftX: point.x, topLeftY: point.y, width: width, height: height)
        switch nodeCases {
            case .workspace(let workspace):
                lastAppliedLayoutPhysicalRect = physicalRect
                lastAppliedLayoutVirtualRect = virtual

                // Layout tiling windows
                try await workspace.layoutMasterStack(point, width: width, height: height, virtual: virtual, context)

                // Layout floating windows
                for window in workspace.children.filterIsInstance(of: Window.self).filter({ $0.isFloating }) {
                    window.lastAppliedLayoutPhysicalRect = nil
                    window.lastAppliedLayoutVirtualRect = nil
                    try await window.layoutFloatingWindow(context)
                }
            case .window(let window):
                if window.windowId != currentlyManipulatedWithMouseWindowId {
                    lastAppliedLayoutVirtualRect = virtual
                    // In flat model, no rootTilingContainer. Check if window is fullscreen and matches criteria.
                    // Assuming mostRecentWindowRecursive logic works on Workspace now.
                    if window.isFullscreen && window == context.workspace.mostRecentWindowRecursive {
                        lastAppliedLayoutPhysicalRect = nil
                        window.layoutFullscreen(context)
                    } else {
                        lastAppliedLayoutPhysicalRect = physicalRect
                        window.isFullscreen = false
                        window.setAxFrame(point, CGSize(width: width, height: height))
                    }
                }
            case .macosMinimizedWindowsContainer, .macosFullscreenWindowsContainer,
                 .macosPopupWindowsContainer, .macosHiddenAppsWindowsContainer:
                return
        }
    }
}

private struct LayoutContext {
    let workspace: Workspace
    let resolvedGaps: ResolvedGaps

    @MainActor
    init(_ workspace: Workspace) {
        self.workspace = workspace
        self.resolvedGaps = ResolvedGaps(gaps: config.gaps, monitor: workspace.workspaceMonitor)
    }
}

extension Window {
    @MainActor
    fileprivate func layoutFloatingWindow(_ context: LayoutContext) async throws {
        let workspace = context.workspace
        let targetMonitor = workspace.workspaceMonitor

        // Optimization: Only check for monitor drift if the workspace's monitor has changed
        // since the last layout of this window.
        // This avoids expensive AX calls (getCenter/getAxTopLeftCorner) on every layout cycle.
        if lastLayoutMonitor?.rect.topLeftCorner != targetMonitor.rect.topLeftCorner {
            let currentMonitor = try await getCenter()?.monitorApproximation
            if let currentMonitor, let windowTopLeftCorner = try await getAxTopLeftCorner(), workspace != currentMonitor.activeWorkspace {
                let xProportion = (windowTopLeftCorner.x - currentMonitor.visibleRect.topLeftX) / currentMonitor.visibleRect.width
                let yProportion = (windowTopLeftCorner.y - currentMonitor.visibleRect.topLeftY) / currentMonitor.visibleRect.height

                let moveTo = workspace.workspaceMonitor
                setAxFrame(CGPoint(
                    x: moveTo.visibleRect.topLeftX + xProportion * moveTo.visibleRect.width,
                    y: moveTo.visibleRect.topLeftY + yProportion * moveTo.visibleRect.height,
                ), nil)
            }
        }
        lastLayoutMonitor = targetMonitor

        if isFullscreen {
            layoutFullscreen(context)
            isFullscreen = false
        }
    }

    @MainActor
    fileprivate func layoutFullscreen(_ context: LayoutContext) {
        let monitorRect = noOuterGapsInFullscreen
            ? context.workspace.workspaceMonitor.visibleRect
            : context.workspace.workspaceMonitor.visibleRectPaddedByOuterGaps
        setAxFrame(monitorRect.topLeftCorner, CGSize(width: monitorRect.width, height: monitorRect.height))
    }
}

extension Workspace {
    @MainActor
    fileprivate func layoutMasterStack(_ point: CGPoint, width: CGFloat, height: CGFloat, virtual: Rect, _ context: LayoutContext) async throws {
        let windows = tilingWindows
        if windows.isEmpty { return }

        if layout == .floating {
            // Treat all as floating? But tilingWindows excludes floating.
            // If layout is floating, maybe we don't tile them at all?
            // DWM "Floating" layout usually means no windows are tiled.
            return
        }

        if windows.count == 1 {
            try await windows[0].layoutRecursive(point, width: width, height: height, virtual: virtual, context)
            return
        }

        let masterWidth: CGFloat
        let masterHeight: CGFloat
        let stackWidth: CGFloat
        let stackHeight: CGFloat

        if orientation == .h {
            masterWidth = width * mfact
            masterHeight = height
            stackWidth = width - masterWidth
            stackHeight = height / CGFloat(windows.count - 1)
        } else {
            masterWidth = width
            masterHeight = height * mfact
            stackWidth = width / CGFloat(windows.count - 1)
            stackHeight = height - masterHeight
        }

        // Master window (first in list)
        try await windows[0].layoutRecursive(point, width: masterWidth, height: masterHeight, virtual: virtual, context)

        // Stack windows
        for i in 1 ..< windows.count {
            let stackPoint: CGPoint = if orientation == .h {
                point.addingXOffset(masterWidth).addingYOffset(CGFloat(i - 1) * stackHeight)
            } else {
                point.addingYOffset(masterHeight).addingXOffset(CGFloat(i - 1) * stackWidth)
            }
            try await windows[i].layoutRecursive(stackPoint, width: stackWidth, height: stackHeight, virtual: virtual, context)
        }
    }
}
