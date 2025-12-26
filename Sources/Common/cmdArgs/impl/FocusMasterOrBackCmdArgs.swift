public struct FocusMasterOrBackCmdArgs: CmdArgs {
    /*conforms*/ public var commonState: CmdArgsCommonState
    public init(rawArgs: StrArrSlice) { self.commonState = .init(rawArgs) }
    public static let parser: CmdParser<Self> = cmdParser(
        kind: .focusMasterOrBack,
        allowInConfig: true,
        help: "USAGE: focus-master-or-back\n\nSwitches focus between the master window and the previously focused window within the same workspace.",
        flags: [:],
        posArgs: [],
    )
}
