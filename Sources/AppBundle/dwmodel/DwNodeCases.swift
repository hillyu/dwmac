import Common

enum DwNodeCases {
    case window(Window)
    case workspace(Workspace)
    case macosMinimizedWindowsContainer(MacosMinimizedWindowsContainer)
    case macosHiddenAppsWindowsContainer(MacosHiddenAppsWindowsContainer)
    case macosFullscreenWindowsContainer(MacosFullscreenWindowsContainer)
    case macosPopupWindowsContainer(MacosPopupWindowsContainer)
}

enum NonLeafDwNodeCases {
    case workspace(Workspace)
    case macosMinimizedWindowsContainer(MacosMinimizedWindowsContainer)
    case macosHiddenAppsWindowsContainer(MacosHiddenAppsWindowsContainer)
    case macosFullscreenWindowsContainer(MacosFullscreenWindowsContainer)
    case macosPopupWindowsContainer(MacosPopupWindowsContainer)
}

enum NonLeafDwNodeKind: Equatable {
    case workspace
    case macosMinimizedWindowsContainer
    case macosHiddenAppsWindowsContainer
    case macosFullscreenWindowsContainer
    case macosPopupWindowsContainer
}

protocol NonLeafDwNodeObject: DwNode {}

extension DwNode {
    var nodeCases: DwNodeCases {
        if let window = self as? Window {
            return .window(window)
        } else if let workspace = self as? Workspace {
            return .workspace(workspace)
        } else if let container = self as? MacosHiddenAppsWindowsContainer {
            return .macosHiddenAppsWindowsContainer(container)
        } else if let container = self as? MacosMinimizedWindowsContainer {
            return .macosMinimizedWindowsContainer(container)
        } else if let container = self as? MacosFullscreenWindowsContainer {
            return .macosFullscreenWindowsContainer(container)
        } else if let container = self as? MacosPopupWindowsContainer {
            return .macosPopupWindowsContainer(container)
        } else {
            die("Unknown tree")
        }
    }
}

extension NonLeafDwNodeObject {
    var cases: NonLeafDwNodeCases {
        if self is Window {
            die("Windows are leaf nodes. They can't have children")
        } else if let workspace = self as? Workspace {
            return .workspace(workspace)
        } else if let container = self as? MacosMinimizedWindowsContainer {
            return .macosMinimizedWindowsContainer(container)
        } else if let container = self as? MacosHiddenAppsWindowsContainer {
            return .macosHiddenAppsWindowsContainer(container)
        } else if let container = self as? MacosFullscreenWindowsContainer {
            return .macosFullscreenWindowsContainer(container)
        } else if let container = self as? MacosPopupWindowsContainer {
            return .macosPopupWindowsContainer(container)
        } else {
            die("Unknown tree \(self)")
        }
    }

    var kind: NonLeafDwNodeKind {
        return switch cases {
            case .workspace: .workspace
            case .macosMinimizedWindowsContainer: .macosMinimizedWindowsContainer
            case .macosFullscreenWindowsContainer: .macosFullscreenWindowsContainer
            case .macosHiddenAppsWindowsContainer: .macosHiddenAppsWindowsContainer
            case .macosPopupWindowsContainer: .macosPopupWindowsContainer
        }
    }
}

enum ChildParentRelation: Equatable {
    case floatingWindow
    case macosNativeFullscreenWindow
    case macosNativeHiddenAppWindow
    case macosNativeMinimizedWindow
    case macosPopupWindow
    case tiling // Direct child of Workspace, treated as Tiling

    case shimContainerRelation
}

func getChildParentRelation(child: DwNode, parent: NonLeafDwNodeObject) -> ChildParentRelation {
    if let relation = getChildParentRelationOrNil(child: child, parent: parent) {
        return relation
    }
    illegalChildParentRelation(child: child, parent: parent)
}

func illegalChildParentRelation(child: DwNode, parent: NonLeafDwNodeObject?) -> Never {
    die("Illegal child-parent relation. Child: \(child), Parent: \((parent ?? child.parent).prettyDescription)")
}

func getChildParentRelationOrNil(child: DwNode, parent: NonLeafDwNodeObject) -> ChildParentRelation? {
    return switch (child.nodeCases, parent.cases) {
        case (.workspace, _): nil

        // Window in Workspace: Could be floating or tiling
        case (.window(let w), .workspace):
            w.isFloating ? .floatingWindow : .tiling

        case (.window, .macosPopupWindowsContainer): .macosPopupWindow
        case (_, .macosPopupWindowsContainer): nil
        case (.macosPopupWindowsContainer, _): nil

        case (.window, .macosMinimizedWindowsContainer): .macosNativeMinimizedWindow
        case (_, .macosMinimizedWindowsContainer): nil
        case (.macosMinimizedWindowsContainer, _): nil

        case (.macosFullscreenWindowsContainer, .workspace): .shimContainerRelation
        case (.window, .macosFullscreenWindowsContainer): .macosNativeFullscreenWindow
        case (.macosFullscreenWindowsContainer, _): nil
        case (_, .macosFullscreenWindowsContainer): nil

        case (.macosHiddenAppsWindowsContainer, .workspace): .shimContainerRelation
        case (.window, .macosHiddenAppsWindowsContainer): .macosNativeHiddenAppWindow
        case (.macosHiddenAppsWindowsContainer, _): nil
        case (_, .macosHiddenAppsWindowsContainer): nil
    }
}
