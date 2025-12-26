import AppKit
import Common

struct LayoutCommand: Command {
    let args: LayoutCmdArgs
    /*conforms*/ var shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) async throws -> Bool {
        guard let target = args.resolveTargetOrReportError(env, io) else { return false }
        guard let window = target.windowOrNil else {
            return io.err(noWindowIsFocused)
        }
        let targetDescription = args.toggleBetween.val.first(where: { !window.matchesDescription($0) })
            ?? args.toggleBetween.val.first.orDie()
        if window.matchesDescription(targetDescription) { return false }
        switch targetDescription {
            case .h_master_stack:
                return changeTilingLayout(io, targetLayout: .masterStack, targetOrientation: .h, window: window)
            case .v_master_stack:
                return changeTilingLayout(io, targetLayout: .masterStack, targetOrientation: .v, window: window)
            case .master_stack:
                return changeTilingLayout(io, targetLayout: .masterStack, targetOrientation: nil, window: window)
            case .horizontal:
                return changeTilingLayout(io, targetLayout: nil, targetOrientation: .h, window: window)
            case .vertical:
                return changeTilingLayout(io, targetLayout: nil, targetOrientation: .v, window: window)
            case .tiling:
                if window.isFloating {
                    window.isFloating = false
                    // Rebind to force update? Or just changing property is enough if we trigger layout?
                    // Window needs to be in workspace children.
                    return true
                }
                return false
            case .floating:
                if !window.isFloating {
                    window.isFloating = true
                    return true
                }
                return false
        }
    }
}

@MainActor private func changeTilingLayout(_ io: CmdIo, targetLayout: Layout?, targetOrientation: Orientation?, window: Window) -> Bool {
    guard let workspace = window.nodeWorkspace else { return false }
    if let targetLayout {
        workspace.layout = targetLayout
    }
    if let targetOrientation {
        workspace.orientation = targetOrientation
    }
    return true
}

extension Window {
    fileprivate func matchesDescription(_ layout: LayoutCmdArgs.LayoutDescription) -> Bool {
        guard let workspace = nodeWorkspace else { return false }
        return switch layout {
            case .horizontal:  !isFloating && workspace.orientation == .h
            case .vertical:    !isFloating && workspace.orientation == .v
            case .tiling:      !isFloating
            case .floating:    isFloating
            case .master_stack: !isFloating && workspace.layout == .masterStack
            case .h_master_stack: !isFloating && workspace.layout == .masterStack && workspace.orientation == .h
            case .v_master_stack: !isFloating && workspace.layout == .masterStack && workspace.orientation == .v
        }
    }
}
