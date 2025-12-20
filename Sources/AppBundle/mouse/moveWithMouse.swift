import AppKit
import Common

@MainActor
private var moveWithMouseTask: Task<(), any Error>? = nil

func movedObs(_ obs: AXObserver, ax: AXUIElement, notif: CFString, data: UnsafeMutableRawPointer?) {
    let windowId = ax.containingWindowId()
    let notif = notif as String
    Task { @MainActor in
        guard let token: RunSessionGuard = .isServerEnabled else { return }
        guard let windowId, let window = Window.get(byId: windowId), try await isManipulatedWithMouse(window) else {
            scheduleRefreshSession(.ax(notif))
            return
        }
        moveWithMouseTask?.cancel()
        moveWithMouseTask = Task {
            try checkCancellation()
            try await runLightSession(.ax(notif), token) {
                try await moveWithMouse(window)
            }
        }
    }
}

@MainActor
private func moveWithMouse(_ window: Window) async throws { // todo cover with tests
    resetClosedWindowsCache()
    if window.isFloating {
        try await moveFloatingWindow(window)
    } else {
        moveTilingWindow(window)
    }
}

@MainActor
private func moveFloatingWindow(_ window: Window) async throws {
    guard let targetWorkspace = try await window.getCenter()?.monitorApproximation.activeWorkspace else { return }
    guard let parent = window.parent else { return }
    if targetWorkspace != parent {
        window.bindAsFloatingWindow(to: targetWorkspace)
    }
}

@MainActor
private func moveTilingWindow(_ window: Window) {
    currentlyManipulatedWithMouseWindowId = window.windowId
    window.lastAppliedLayoutPhysicalRect = nil
    let mouseLocation = mouseLocation
    let targetWorkspace = mouseLocation.monitorApproximation.activeWorkspace
    
    // Find window under cursor in target workspace
    let swapTarget = mouseLocation.findIn(workspace: targetWorkspace, virtual: false)?.takeIf { $0 != window }
    
    if targetWorkspace != window.nodeWorkspace { // Move window to a different monitor
        // Calculate insertion index
        let index: Int
        if let swapTarget {
             // In flat list, insert after or before based on orientation?
             // Or just swap? DWM usually moves window to master when moving monitors.
             // Or append to end.
             // Let's use simple logic: append to end for now or next to swapTarget.
             
             // If we want to support insertion at specific index:
             // Check if mouse is "after" the center of target window in orientation direction.
             if let rect = swapTarget.lastAppliedLayoutPhysicalRect {
                 let projMouse = mouseLocation.getProjection(targetWorkspace.orientation)
                 let projCenter = rect.center.getProjection(targetWorkspace.orientation)
                 index = projMouse >= projCenter ? (swapTarget.ownIndex ?? 0) + 1 : (swapTarget.ownIndex ?? 0)
             } else {
                 index = 0
             }
        } else {
            index = 0
        }
        window.bind(
            to: targetWorkspace,
            adaptiveWeight: WEIGHT_AUTO,
            index: index, // This index is in `children`, which mixes types. Might be buggy if not careful.
            // But bind() inserts at index.
        )
    } else if let swapTarget {
        swapWindows(window, swapTarget)
    }
}

@MainActor
func swapWindows(_ window1: Window, _ window2: Window) {
    if window1 == window2 { return }
    guard let index1 = window1.ownIndex else { return }
    guard let index2 = window2.ownIndex else { return }

    if index1 < index2 {
        let binding2 = window2.unbindFromParent()
        let binding1 = window1.unbindFromParent()

        window2.bind(to: binding1.parent, adaptiveWeight: binding1.adaptiveWeight, index: binding1.index)
        window1.bind(to: binding2.parent, adaptiveWeight: binding2.adaptiveWeight, index: binding2.index)
    } else {
        let binding1 = window1.unbindFromParent()
        let binding2 = window2.unbindFromParent()

        window1.bind(to: binding2.parent, adaptiveWeight: binding2.adaptiveWeight, index: binding2.index)
        window2.bind(to: binding1.parent, adaptiveWeight: binding1.adaptiveWeight, index: binding1.index)
    }
}

extension CGPoint {
    @MainActor
    func findIn(workspace: Workspace, virtual: Bool) -> Window? {
        let point = self
        // Only search tiling windows
        return workspace.tilingWindows.first(where: {
            (virtual ? $0.lastAppliedLayoutVirtualRect : $0.lastAppliedLayoutPhysicalRect)?.contains(point) == true
        })
    }
}
