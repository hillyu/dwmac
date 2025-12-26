import AppKit
import Common

struct MfactCommand: Command {
    let args: MfactCmdArgs
    /*conforms*/ var shouldResetClosedWindowsCache = false

    func run(_ env: CmdEnv, _ io: CmdIo) async throws -> Bool {
        guard let window = focus.windowOrNil else { return false }
        guard let workspace = window.nodeWorkspace else { return false }

        if workspace.layout != .masterStack { return false }

        switch args.amount.val {
            case .set(let value): workspace.mfact = CGFloat(value)
            case .add(let value): workspace.mfact += CGFloat(value)
            case .subtract(let value): workspace.mfact -= CGFloat(value)
        }

        // Clamp
        if workspace.mfact < 0.05 { workspace.mfact = 0.05 }
        if workspace.mfact > 0.95 { workspace.mfact = 0.95 }

        return true
    }
}
