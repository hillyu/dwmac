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
                let nextIndex: Int = if direction == .right || direction == .down {
                    currentIndex + 1
                } else {
                    currentIndex - 1
                }

                if (0 ..< windows.count).contains(nextIndex) {
                    targetWindow = windows[nextIndex]
                } else if args.wrapAround {
                    targetWindow = (direction == .right || direction == .down) ? windows.first : windows.last
                } else {
                    return false
                }
            case .relative(let nextPrev):
                var targetIndex = switch nextPrev {
                    case .next: currentIndex + 1
                    case .prev: currentIndex - 1
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
