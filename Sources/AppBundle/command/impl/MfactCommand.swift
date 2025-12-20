import AppKit
import Common

struct MfactCommand: Command {
    let args: MfactCmdArgs
    /*conforms*/ var shouldResetClosedWindowsCache = false

    func run(_ env: CmdEnv, _ io: CmdIo) async throws -> Bool {
        guard let window = focus.windowOrNil else { return false }

        var current: TreeNode? = window.parent
        var targetContainer: TilingContainer?

        // Search up for a master-stack container
        while let node = current {
            if let container = node as? TilingContainer, container.layout == .masterStack {
                targetContainer = container
                break
            }
            current = node.parent
        }

        guard let container = targetContainer else {
            return false
        }

        switch args.amount.val {
            case .set(let value): container.mfact = CGFloat(value)
            case .add(let value): container.mfact += CGFloat(value)
            case .subtract(let value): container.mfact -= CGFloat(value)
        }

        // Clamp
        if container.mfact < 0.05 { container.mfact = 0.05 }
        if container.mfact > 0.95 { container.mfact = 0.95 }

        return true
    }
}
