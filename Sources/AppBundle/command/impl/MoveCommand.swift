import AppKit
import Common

struct MoveCommand: Command {
    let args: MoveCmdArgs
    /*conforms*/ var shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) async throws -> Bool {
        guard let target = args.resolveTargetOrReportError(env, io) else { return false }
        guard let window = target.windowOrNil else { return false }

        if !window.isFloating {
            return io.err("move command only supports floating windows")
        }

        guard let rect = try? await window.getAxRect() else { return false }
        var newOrigin = rect.topLeftCorner
        let step: CGFloat = 50

        switch args.direction.val {
            case .left:  newOrigin.x -= step
            case .right: newOrigin.x += step
            case .up:    newOrigin.y -= step
            case .down:  newOrigin.y += step
        }

        window.setAxFrame(newOrigin, nil)

        return true
    }
}
