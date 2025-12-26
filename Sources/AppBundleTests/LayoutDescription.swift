@testable import AppBundle
import Common

extension DwNode {
    var layoutDescription: LayoutDescription {
        return switch nodeCases {
            case .window(let window): .window(window.windowId)
            case .workspace(let workspace):
                workspace.orientation == .h
                    ? .h_master_stack(workspace.children.map(\.layoutDescription))
                    : .v_master_stack(workspace.children.map(\.layoutDescription))
            case .macosMinimizedWindowsContainer: .macosMinimized
            case .macosFullscreenWindowsContainer: .macosFullscreen
            case .macosHiddenAppsWindowsContainer: .macosHiddeAppWindow
            case .macosPopupWindowsContainer: .macosPopupWindowsContainer
        }
    }
}

enum LayoutDescription: Equatable {
    case workspace([LayoutDescription])
    case h_master_stack([LayoutDescription])
    case v_master_stack([LayoutDescription])
    case window(UInt32)
    case macosPopupWindowsContainer
    case macosMinimized
    case macosHiddeAppWindow
    case macosFullscreen
}
