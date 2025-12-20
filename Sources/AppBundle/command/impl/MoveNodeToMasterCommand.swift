import AppKit
import Common

struct MoveNodeToMasterCommand: Command {
    let args: MoveNodeToMasterCmdArgs
    /*conforms*/ var shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) async throws -> Bool {
        guard let window = focus.windowOrNil else { return false }
        guard let parent = window.parent as? TilingContainer else { return false }

        let targetIndex = 0
        if window.ownIndex == targetIndex {
            return true
        }

        window.bind(to: parent, adaptiveWeight: WEIGHT_AUTO, index: targetIndex)
        return true
    }
}
