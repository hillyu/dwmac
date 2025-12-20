import Common

struct CmdEnv: ConvenienceCopyable {
    var windowId: UInt32?
    var workspaceName: String?

    static let defaultEnv: CmdEnv = .init()
    func withFocus(_ focus: LiveFocus) -> CmdEnv {
        switch focus.asLeaf {
            case .window(let wd): .defaultEnv.copy(\.windowId, wd.windowId)
            case .emptyWorkspace(let ws): .defaultEnv.copy(\.workspaceName, ws.name)
        }
    }

    @MainActor
    var asMap: [String: String] {
        var result = config.execConfig.envVariables
        if let windowId {
            result[DWMAC_WINDOW_ID] = windowId.description
        }
        if let workspaceName {
            result[DWMAC_WORKSPACE] = workspaceName.description
        }
        return result
    }
}
