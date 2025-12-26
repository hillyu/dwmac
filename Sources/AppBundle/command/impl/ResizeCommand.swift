import AppKit
import Common

struct ResizeCommand: Command {
    let args: ResizeCmdArgs
    /*conforms*/ var shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) async throws -> Bool {
        guard let target = args.resolveTargetOrReportError(env, io) else { return false }
        guard let window = target.windowOrNil else { return false }

        if !window.isFloating {
            return io.err("resize command only supports floating windows")
        }

        guard let rect = try? await window.getAxRect() else { return false }
        var newSize = rect.size

        let diff: CGFloat = switch args.units.val {
            case .set(let unit): CGFloat(unit)
            case .add(let unit): CGFloat(unit)
            case .subtract(let unit): -CGFloat(unit)
        }

        // Helper to apply change
        func apply(_ current: CGFloat) -> CGFloat {
            if case .set = args.units.val {
                return diff
            } else {
                return current + diff
            }
        }

        switch args.dimension.val {
            case .width:
                newSize.width = apply(newSize.width)
            case .height:
                newSize.height = apply(newSize.height)
            case .smart:
                // Default to width for smart on floating
                newSize.width = apply(newSize.width)
            case .smartOpposite:
                // Default to height for smart-opposite on floating
                newSize.height = apply(newSize.height)
        }

        // Prevent collapsing to zero/negative
        newSize.width = max(10, newSize.width)
        newSize.height = max(10, newSize.height)

        window.setAxFrame(rect.topLeftCorner, newSize)

        return true
    }
}
