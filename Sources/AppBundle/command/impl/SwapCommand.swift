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

        var targetIndex = switch args.target.val {
            case .next: currentIndex + 1
            case .prev: currentIndex - 1
        }
        if !(0 ..< windows.count).contains(targetIndex) {
            if !args.wrapAround {
                return false
            }
            targetIndex = (targetIndex + windows.count) % windows.count
        }
        let targetWindow = windows[targetIndex]

        swapWindows(currentWindow, targetWindow)

        if args.swapFocus {
            return targetWindow.focusWindow()
        }
        return true
    }
}
