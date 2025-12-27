import AppKit
import Common

struct FocusCommand: Command {
    let args: FocusCmdArgs
    /*conforms*/ var shouldResetClosedWindowsCache = false

    func run(_ env: CmdEnv, _ io: CmdIo) async throws -> Bool {
        guard let target = args.resolveTargetOrReportError(env, io) else { return false }

        // Simplified: Ignore floating-as-tiling complexity for now

        switch args.target {
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
