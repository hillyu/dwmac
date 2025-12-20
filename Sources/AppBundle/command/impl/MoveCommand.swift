import AppKit
import Common

struct MoveCommand: Command {
    let args: MoveCmdArgs
    /*conforms*/ var shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
        let direction = args.direction.val
        guard let target = args.resolveTargetOrReportError(env, io) else { return false }
        guard let currentWindow = target.windowOrNil else {
            return io.err(noWindowIsFocused)
        }
        guard let workspace = currentWindow.nodeWorkspace else { return false }

        if currentWindow.isFloating {
            return io.err("moving floating windows isn't yet supported")
        }

        let windows = workspace.tilingWindows
        guard let currentIndex = windows.firstIndex(of: currentWindow) else { return false }

        let targetIndex: Int = if direction == .right || direction == .down {
            currentIndex + 1
        } else {
            currentIndex - 1
        }

        if (0 ..< windows.count).contains(targetIndex) {
            // ...

            let targetWindow = windows[targetIndex]
            if !workspace.children.contains(targetWindow) { return false }

            let weight = currentWindow.getWeight(workspace.orientation)
            currentWindow.unbindFromParent()
            // Re-find target index as it might have shifted
            guard let newTargetIndex = workspace.children.firstIndex(of: targetWindow) else { return false }

            let insertionIndex: Int = if direction == .right || direction == .down {
                newTargetIndex + 1
            } else {
                newTargetIndex
            }

            currentWindow.bind(to: workspace, adaptiveWeight: weight, index: insertionIndex)
            return true
        } else {
            return hitWorkspaceBoundaries(currentWindow, workspace, io, args, direction, env)
        }
    }
}

@MainActor private func hitWorkspaceBoundaries(
    _ window: Window,
    _ workspace: Workspace,
    _ io: CmdIo,
    _ args: MoveCmdArgs,
    _ direction: CardinalDirection,
    _ env: CmdEnv,
) -> Bool {
    switch args.boundaries {
        case .workspace:
            switch args.boundariesAction {
                case .stop: return true
                case .fail: return false
                case .createImplicitContainer:
                    // In flat model, this might mean creating a split? But we removed splits.
                    // So effectively no-op or error.
                    return io.err("Implicit containers are not supported in DWM mode")
            }
        case .allMonitorsOuterFrame:
            guard let (monitors, index) = window.nodeMonitor?.findRelativeMonitor(inDirection: direction) else {
                return io.err("Should never happen. Can't find the current monitor")
            }

            if monitors.indices.contains(index) {
                let moveNodeToMonitorArgs = MoveNodeToMonitorCmdArgs(target: .direction(direction))
                    .copy(\.windowId, window.windowId)
                    .copy(\.focusFollowsWindow, focus.windowOrNil == window)

                return MoveNodeToMonitorCommand(args: moveNodeToMonitorArgs).run(env, io)
            } else {
                return hitAllMonitorsOuterFrameBoundaries(window, workspace, io, args, direction)
            }
    }
}

@MainActor private func hitAllMonitorsOuterFrameBoundaries(
    _ window: Window,
    _ workspace: Workspace,
    _ io: CmdIo,
    _ args: MoveCmdArgs,
    _ direction: CardinalDirection,
) -> Bool {
    switch args.boundariesAction {
        case .stop: return true
        case .fail: return false
        case .createImplicitContainer:
            return io.err("Implicit containers are not supported in DWM mode")
    }
}
