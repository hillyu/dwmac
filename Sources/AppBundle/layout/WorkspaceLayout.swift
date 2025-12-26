import AppKit

extension Workspace {
    @MainActor
    func layoutWorkspace() async throws {
        if isEffectivelyEmpty { return }
        let rect = workspaceMonitor.visibleRectPaddedByOuterGaps
        let context = LayoutContext(self)

        // Layout tiling windows
        try await layoutMasterStack(rect.topLeftCorner, width: rect.width, height: rect.height - 1, virtual: rect, context)

        // Layout floating windows
        for window in children.filterIsInstance(of: Window.self).filter({ $0.isFloating }) {
            window.lastAppliedLayoutPhysicalRect = nil
            window.lastAppliedLayoutVirtualRect = nil
            try await window.layoutFloatingWindow(context)
        }
    }

    @MainActor
    private func layoutMasterStack(_ point: CGPoint, width: CGFloat, height: CGFloat, virtual: Rect, _ context: LayoutContext) async throws {
        let windows = tilingWindows
        if windows.isEmpty { return }

        if layout == .floating {
            return
        }

        if windows.count == 1 {
            let window = windows[0]
            try await layoutWindow(window, point, width, height, virtual, context)
            return
        }

        let gaps = context.resolvedGaps.inner
        let gapH = CGFloat(gaps.horizontal)
        let gapV = CGFloat(gaps.vertical)

        let masterWidth: CGFloat
        let masterHeight: CGFloat
        let stackWidth: CGFloat
        let stackHeight: CGFloat

        if orientation == .h {
            masterWidth = (width - gapH) * mfact
            masterHeight = height
            stackWidth = width - masterWidth - gapH
            stackHeight = (height - CGFloat(windows.count - 2) * gapV) / CGFloat(windows.count - 1)
        } else {
            masterWidth = width
            masterHeight = (height - gapV) * mfact
            stackWidth = (width - CGFloat(windows.count - 2) * gapH) / CGFloat(windows.count - 1)
            stackHeight = height - masterHeight - gapV
        }

        // Master window (first in list)
        try await layoutWindow(windows[0], point, masterWidth, masterHeight, virtual, context)

        // Stack windows
        for i in 1 ..< windows.count {
            let stackPoint: CGPoint = if orientation == .h {
                point.addingXOffset(masterWidth + gapH).addingYOffset(CGFloat(i - 1) * (stackHeight + gapV))
            } else {
                point.addingYOffset(masterHeight + gapV).addingXOffset(CGFloat(i - 1) * (stackWidth + gapH))
            }
            try await layoutWindow(windows[i], stackPoint, stackWidth, stackHeight, virtual, context)
        }
    }

    @MainActor
    private func layoutWindow(_ window: Window, _ point: CGPoint, _ width: CGFloat, _ height: CGFloat, _ virtual: Rect, _ context: LayoutContext) async throws {
        let physicalRect = Rect(topLeftX: point.x, topLeftY: point.y, width: width, height: height)

        if window.windowId != currentlyManipulatedWithMouseWindowId {
            window.lastAppliedLayoutVirtualRect = virtual
            // In flat model, no rootTilingContainer. Check if window is fullscreen and matches criteria.
            // Assuming mostRecentWindowRecursive logic works on Workspace now.
            if window.isFullscreen && window == context.workspace.mostRecentWindowRecursive {
                window.lastAppliedLayoutPhysicalRect = nil
                window.layoutFullscreen(context)
            } else {
                window.lastAppliedLayoutPhysicalRect = physicalRect
                window.isFullscreen = false
                window.setAxFrame(point, CGSize(width: width, height: height))
            }
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
