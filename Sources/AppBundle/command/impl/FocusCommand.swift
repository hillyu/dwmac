import AppKit
import Common

struct FocusCommand: Command {
    let args: FocusCmdArgs
    /*conforms*/ var shouldResetClosedWindowsCache = false

    func run(_ env: CmdEnv, _ io: CmdIo) async throws -> Bool {
        guard let target = args.resolveTargetOrReportError(env, io) else { return false }

        // Simplified: Ignore floating-as-tiling complexity for now

        switch args.target {
            case .direction(let direction):
                guard let window = target.windowOrNil else { return false }
                guard let workspace = window.nodeWorkspace else { return false }

                // In flat master-stack:
                // Up/Down = Prev/Next window in list
                // Left/Right = Swap between Master and Stack areas? Or move focus to monitor?
                // For now, let's map Up/Left to Prev, Down/Right to Next?
                // Or try to mimic spatial relation in the list?

                // Actually, existing logic used tree traversal.
                // New logic: Just use index in the list.
                let windows = workspace.allWindows
                guard let currentIndex = windows.firstIndex(of: window) else { return false }

                let nextIndex: Int = if direction == .right || direction == .down {
                    currentIndex + 1
                } else {
                    currentIndex - 1
                }

                if (0 ..< windows.count).contains(nextIndex) {
                    return windows[nextIndex].focusWindow()
                } else {
                    return hitWorkspaceBoundaries(target, io, args, direction)
                }

            case .windowId(let windowId):
                if let windowToFocus = Window.get(byId: windowId) {
                    return windowToFocus.focusWindow()
                } else {
                    return io.err("Can't find window with ID \(windowId)")
                }
            case .index(let index):
                let windows = target.workspace.allWindows
                if let windowToFocus = windows.getOrNil(atIndex: Int(index)) {
                    return windowToFocus.focusWindow()
                } else {
                    return io.err("Can't find window with index \(index)")
                }
            case .relative(let nextPrev):
                let windows = target.workspace.allWindows
                guard let currentIndex = windows.firstIndex(where: { $0 == target.windowOrNil }) else {
                    return false
                }
                var targetIndex = switch nextPrev {
                    case .next: currentIndex + 1
                    case .prev: currentIndex - 1
                }
                if !(0 ..< windows.count).contains(targetIndex) {
                    let action = args.rawBoundariesAction ?? .wrapAroundTheWorkspace
                    switch action {
                        case .stop: return true
                        case .fail: return false
                        case .wrapAroundTheWorkspace: targetIndex = (targetIndex + windows.count) % windows.count
                        case .wrapAroundAllMonitors: return dieT("Must be discarded by args parser")
                    }
                }
                return windows[targetIndex].focusWindow()
        }
    }
}

@MainActor private func hitWorkspaceBoundaries(
    _ target: LiveFocus,
    _ io: CmdIo,
    _ args: FocusCmdArgs,
    _ direction: CardinalDirection,
) -> Bool {
    switch args.boundaries {
        case .workspace:
            return switch args.boundariesAction {
                case .stop: true
                case .fail: false
                case .wrapAroundTheWorkspace: wrapAroundTheWorkspace(target, io, direction)
                case .wrapAroundAllMonitors: dieT("Must be discarded by args parser")
            }
        case .allMonitorsOuterFrame:
            let currentMonitor = target.workspace.workspaceMonitor
            guard let (monitors, index) = currentMonitor.findRelativeMonitor(inDirection: direction) else {
                return io.err("Should never happen. Can't find the current monitor")
            }

            if let targetMonitor = monitors.getOrNil(atIndex: index) {
                return targetMonitor.activeWorkspace.focusWorkspace()
            } else {
                guard let wrapped = monitors.get(wrappingIndex: index) else { return false }
                return hitAllMonitorsOuterFrameBoundaries(target, io, args, direction, wrapped)
            }
    }
}

@MainActor private func hitAllMonitorsOuterFrameBoundaries(
    _ target: LiveFocus,
    _ io: CmdIo,
    _ args: FocusCmdArgs,
    _ direction: CardinalDirection,
    _ wrappedMonitor: Monitor,
) -> Bool {
    switch args.boundariesAction {
        case .stop:
            return true
        case .fail:
            return false
        case .wrapAroundTheWorkspace:
            return wrapAroundTheWorkspace(target, io, direction)
        case .wrapAroundAllMonitors:
            // Just focus last window
            wrappedMonitor.activeWorkspace.allWindows.last?.markAsMostRecentChild()
            return wrappedMonitor.activeWorkspace.focusWorkspace()
    }
}

@MainActor private func wrapAroundTheWorkspace(_ target: LiveFocus, _ io: CmdIo, _ direction: CardinalDirection) -> Bool {
    let windows = target.workspace.allWindows
    guard !windows.isEmpty else { return io.err(noWindowIsFocused) }

    let windowToFocus = (direction == .right || direction == .down) ? windows.first : windows.last
    return windowToFocus?.focusWindow() ?? false
}
