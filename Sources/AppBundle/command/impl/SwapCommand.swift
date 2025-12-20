import AppKit
import Common

struct SwapCommand: Command {
    let args: SwapCmdArgs
    /*conforms*/ let shouldResetClosedWindowsCache: Bool = true

    func run(_ env: CmdEnv, _ io: CmdIo) async throws -> Bool {
        guard let target = args.resolveTargetOrReportError(env, io) else {
            return false
        }

        guard let currentWindow = target.windowOrNil else {
            return io.err(noWindowIsFocused)
        }
        guard let workspace = currentWindow.nodeWorkspace else { return false }
        
        let windows = workspace.tilingWindows
        guard let currentIndex = windows.firstIndex(of: currentWindow) else { return false }

        let targetWindow: Window?
        switch args.target.val {
            case .direction(let direction):
                let nextIndex: Int
                if direction == .right || direction == .down {
                    nextIndex = currentIndex + 1
                } else {
                    nextIndex = currentIndex - 1
                }
                
                if (0..<windows.count).contains(nextIndex) {
                    targetWindow = windows[nextIndex]
                } else if args.wrapAround {
                    targetWindow = (direction == .right || direction == .down) ? windows.first : windows.last
                } else {
                    return false
                }
            case .dfsRelative(let nextPrev):
                var targetIndex = switch nextPrev {
                    case .dfsNext: currentIndex + 1
                    case .dfsPrev: currentIndex - 1
                }
                if !(0 ..< windows.count).contains(targetIndex) {
                    if !args.wrapAround {
                        return false
                    }
                    targetIndex = (targetIndex + windows.count) % windows.count
                }
                targetWindow = windows[targetIndex]
        }

        guard let targetWindow else {
            return false
        }

        swapWindows(currentWindow, targetWindow)

        if args.swapFocus {
            return targetWindow.focusWindow()
        }
        return true
    }
}

extension Workspace {
    // Assuming this extension exists or should exist in Workspace.swift or here
    // var tilingWindows: [Window] {
    //    children.filterIsInstance(of: Window.self).filter { !$0.isFloating }
    // }
}
