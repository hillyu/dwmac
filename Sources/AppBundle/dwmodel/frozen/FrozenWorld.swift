struct FrozenWorld {
    let workspaces: [FrozenWorkspace]
    let monitors: [FrozenMonitor]
    let windowIds: Set<UInt32>
}

@MainActor
func collectAllWindowIds(workspace: Workspace) -> [UInt32] {
    workspace.floatingWindows.map { $0.windowId } +
        workspace.macOsNativeFullscreenWindowsContainer.children.map { ($0 as! Window).windowId } +
        workspace.macOsNativeHiddenAppsWindowsContainer.children.map { ($0 as! Window).windowId } +
        workspace.tilingWindows.map { $0.windowId }
}
