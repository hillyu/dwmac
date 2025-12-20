import AppKit
import Common

struct ResizeCommand: Command { // todo cover with tests
    let args: ResizeCmdArgs
    /*conforms*/ var shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
        guard let target = args.resolveTargetOrReportError(env, io) else { return false }
        guard let window = target.windowOrNil else { return false }
        guard let workspace = window.nodeWorkspace else { return false }
        
        if window.isFloating {
             return io.err("resize command doesn't support floating windows yet")
        }
        if workspace.layout != .masterStack {
             return false
        }

        let orientation: Orientation?
        switch args.dimension.val {
            case .width:
                orientation = .h
            case .height:
                orientation = .v
            case .smart:
                orientation = workspace.orientation
            case .smartOpposite:
                orientation = workspace.orientation.opposite
        }
        
        guard let orientation else { return false }
        
        if orientation != workspace.orientation {
             return io.err("Can't resize in \(orientation) direction because container orientation is \(workspace.orientation)")
        }

        let diff: CGFloat = switch args.units.val {
            case .set(let unit): CGFloat(unit) - window.getWeight(orientation)
            case .add(let unit): CGFloat(unit)
            case .subtract(let unit): -CGFloat(unit)
        }

        guard let childDiff = diff.div(workspace.children.count - 1) else { return false }
        workspace.children.lazy
            .filter { $0 != window }
            // Only tiling windows have weight? No, TreeNode has weight.
            .forEach { $0.setWeight(workspace.orientation, $0.getWeight(workspace.orientation) - childDiff) }

        window.setWeight(orientation, window.getWeight(orientation) + diff)
        return true
    }
}
