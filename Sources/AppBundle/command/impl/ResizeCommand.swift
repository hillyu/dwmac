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

        let orientation: Orientation? = switch args.dimension.val {
            case .width:
                .h
            case .height:
                .v
            case .smart:
                workspace.orientation
            case .smartOpposite:
                workspace.orientation.opposite
        }

        guard let orientation else { return false }

        if orientation != workspace.orientation {
            // Stack vs Stack resizing not supported yet
            return io.err("Resizing stack windows relative to each other is not supported. Use 'resize smart' or match workspace orientation to resize Master area.")
        }

        let tilingWindows = workspace.tilingWindows
        guard let index = tilingWindows.firstIndex(of: window) else { return false }

        // If single window, resize makes no sense (it fills space)
        if tilingWindows.count < 2 { return true }

        let totalSize = workspace.workspaceMonitor.visibleRectPaddedByOuterGaps.getDimension(orientation)

        let diff: CGFloat = switch args.units.val {
            case .set(let unit): CGFloat(unit) // How to interpret set?
            case .add(let unit): CGFloat(unit)
            case .subtract(let unit): -CGFloat(unit)
        }

        // If Set, we need special handling.
        // If Set < 1, assume ratio. If > 1, assume pixels.
        // But let's simplify and handle add/sub first which is most common.

        if case .set(let unit) = args.units.val {
            let ratio = CGFloat(unit) < 1 ? CGFloat(unit) : CGFloat(unit) / totalSize
            if index == 0 {
                workspace.mfact = ratio
            } else {
                // Setting stack size? means Master size = 1 - ratio
                workspace.mfact = 1 - ratio
            }
        } else {
            let ratioDiff = diff / totalSize
            if index == 0 {
                workspace.mfact += ratioDiff
            } else {
                workspace.mfact -= ratioDiff
            }
        }

        // Clamp mfact
        workspace.mfact = workspace.mfact.coerceIn(0.05 ... 0.95)

        return true
    }
}
