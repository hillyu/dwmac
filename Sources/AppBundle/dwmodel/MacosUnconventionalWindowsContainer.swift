import Common

final class MacosFullscreenWindowsContainer: DwNode, NonLeafDwNodeObject {
    @MainActor
    init(parent: Workspace) {
        super.init(parent: parent, index: INDEX_BIND_LAST)
    }
}

/// The container for macOS windows of hidden apps
final class MacosHiddenAppsWindowsContainer: DwNode, NonLeafDwNodeObject {
    @MainActor
    init(parent: Workspace) {
        super.init(parent: parent, index: INDEX_BIND_LAST)
    }
}

@MainActor let macosMinimizedWindowsContainer = MacosMinimizedWindowsContainer()
final class MacosMinimizedWindowsContainer: DwNode, NonLeafDwNodeObject {
    @MainActor
    fileprivate init() {
        super.init(parent: NilDwNode.instance, index: INDEX_BIND_LAST)
    }
}

@MainActor let macosPopupWindowsContainer = MacosPopupWindowsContainer()
/// The container for macOS objects that are windows from AX perspective but from human perspective they are not even
/// dialogs. E.g. Sonoma (macOS 14) keyboard layout switch
final class MacosPopupWindowsContainer: DwNode, NonLeafDwNodeObject {
    @MainActor
    fileprivate init() {
        super.init(parent: NilDwNode.instance, index: INDEX_BIND_LAST)
    }
}
