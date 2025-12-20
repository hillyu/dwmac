public struct MoveNodeToMasterCmdArgs: CmdArgs {
    public var commonState: CmdArgsCommonState

    public init(rawArgs: StrArrSlice) {
        self.commonState = .init(rawArgs)
    }

    public static let parser: CmdParser<Self> = cmdParser(
        kind: .moveNodeToMaster,
        allowInConfig: true,
        help: "usage: move-node-to-master",
        flags: [:],
        posArgs: [],
    )
}
