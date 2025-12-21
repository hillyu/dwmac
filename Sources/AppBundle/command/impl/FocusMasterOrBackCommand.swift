import AppKit
import Common

private let lastNonMasterFocusedWindowKey = TreeNodeUserDataKey<UInt32>(key: "focus-master-or-back.lastNonMasterFocusedWindow")

struct FocusMasterOrBackCommand: Command {
    let args: FocusMasterOrBackCmdArgs
    var shouldResetClosedWindowsCache = false

    func run(_ env: CmdEnv, _ io: CmdIo) async throws -> Bool {
        guard let currentWindow = focus.windowOrNil else { return false }
        guard let workspace = currentWindow.nodeWorkspace else { return false }

        // Identify master window: The first non-floating window in the workspace
        let masterWindow = workspace.allLeafWindowsRecursive.first(where: { !$0.isFloating })

        guard let master = masterWindow else { return false }

        if currentWindow == master {
            // Restore last focused non-master window
            if let windowId = workspace.getUserData(key: lastNonMasterFocusedWindowKey),
               let window = workspace.allLeafWindowsRecursive.first(where: { $0.windowId == windowId })
            {
                return window.focusWindow()
            } else {
                return false
            }
        } else {
            // Focus master and save current
            workspace.putUserData(key: lastNonMasterFocusedWindowKey, data: currentWindow.windowId)
            return master.focusWindow()
        }
    }
}
