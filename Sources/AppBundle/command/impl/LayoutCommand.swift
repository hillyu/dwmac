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
        guard let parent = window.parent else { return false }
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
                switch parent.cases {
                    case .tilingContainer: return false
                    case .workspace(let workspace):
                        window.bind(to: workspace.rootTilingContainer, adaptiveWeight: WEIGHT_AUTO, index: INDEX_BIND_LAST)
                        return true
                    case .macosMinimizedWindowsContainer, .macosFullscreenWindowsContainer,
                         .macosPopupWindowsContainer, .macosHiddenAppsWindowsContainer:
                        return io.err("The window is non-tiling")
                }
            case .floating:
                switch parent.cases {
                    case .tilingContainer:
                        guard let workspace = window.nodeWorkspace else { return false }
                        window.bindAsFloatingWindow(to: workspace)
                        return true
                    case .workspace: return false
                    case .macosMinimizedWindowsContainer, .macosFullscreenWindowsContainer,
                         .macosPopupWindowsContainer, .macosHiddenAppsWindowsContainer:
                        return io.err("The window is non-tiling")
                }
        }
    }
}

@MainActor private func changeTilingLayout(_ io: CmdIo, targetLayout: Layout?, targetOrientation: Orientation?, window: Window) -> Bool {
    guard let parent = window.parent else { return false }
    switch parent.cases {
        case .tilingContainer(let parent):
            let targetOrientation = targetOrientation ?? parent.orientation
            let targetLayout = targetLayout ?? parent.layout
            parent.layout = targetLayout
            parent.changeOrientation(targetOrientation)
            return true
        case .workspace, .macosMinimizedWindowsContainer, .macosFullscreenWindowsContainer,
             .macosPopupWindowsContainer, .macosHiddenAppsWindowsContainer:
            return io.err("The window is non-tiling")
    }
}

extension Window {
    fileprivate func matchesDescription(_ layout: LayoutCmdArgs.LayoutDescription) -> Bool {
        return switch layout {
            case .horizontal:  (parent as? TilingContainer)?.orientation == .h
            case .vertical:    (parent as? TilingContainer)?.orientation == .v
            case .tiling:      parent is TilingContainer
            case .floating:    !(parent is TilingContainer)
            case .master_stack: (parent as? TilingContainer)?.layout == .masterStack
            case .h_master_stack: (parent as? TilingContainer)?.layout == .masterStack && (parent as? TilingContainer)?.orientation == .h
            case .v_master_stack: (parent as? TilingContainer)?.layout == .masterStack && (parent as? TilingContainer)?.orientation == .v
        }
    }
}
