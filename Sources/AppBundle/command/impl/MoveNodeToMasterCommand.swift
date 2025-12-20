import AppKit
import Common

struct MoveNodeToMasterCommand: Command {
    let args: MoveNodeToMasterCmdArgs
    /*conforms*/ var shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) async throws -> Bool {
        guard let window = focus.windowOrNil else { return false }
        guard let workspace = window.nodeWorkspace else { return false }
        if window.isFloating { return false }

        // Window is already in workspace children.
        // We need to reorder it to index 0 among TILING windows.
        
        // This is tricky because `workspace.children` contains both tiling and floating.
        // But `bind` takes an index in `children`.
        // So we need to find the index of the first tiling window.
        
        let firstTilingIndex = workspace.children.firstIndex(where: { ($0 as? Window)?.isFloating == false }) ?? 0
        
        window.bind(to: workspace, adaptiveWeight: WEIGHT_AUTO, index: firstTilingIndex)
        return true
    }
}
