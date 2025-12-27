public struct SwapCmdArgs: CmdArgs {
    /*conforms*/ public var commonState: CmdArgsCommonState
    public init(rawArgs: StrArrSlice) { self.commonState = .init(rawArgs) }
    public static let parser: CmdParser<Self> = cmdParser(
        kind: .swap,
        allowInConfig: true,
        help: swap_help_generated,
        flags: [
            "--swap-focus": trueBoolFlag(\.swapFocus),
            "--wrap-around": trueBoolFlag(\.wrapAround),
            "--window-id": optionalWindowIdFlag(),
        ],
        posArgs: [newArgParser(\.target, parseNextPrevArg, mandatoryArgPlaceholder: NextPrev.unionLiteral)],
    )

    public var target: Lateinit<NextPrev> = .uninitialized
    public var swapFocus: Bool = false
    public var wrapAround: Bool = false

    public init(rawArgs: [String], target: NextPrev) {
        self.commonState = .init(rawArgs.slice)
        self.target = .initialized(target)
    }
}

public func parseSwapCmdArgs(_ args: StrArrSlice) -> ParsedCmd<SwapCmdArgs> {
    return parseSpecificCmdArgs(SwapCmdArgs(rawArgs: args), args)
}
