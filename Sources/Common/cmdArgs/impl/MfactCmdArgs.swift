public struct MfactCmdArgs: CmdArgs {
    public var commonState: CmdArgsCommonState
    public init(rawArgs: StrArrSlice) { self.commonState = .init(rawArgs) }
    public static let parser: CmdParser<Self> = cmdParser(
        kind: .mfact,
        allowInConfig: true,
        help: "Usage: mfact [+|-]<number>",
        flags: [:],
        posArgs: [
            newArgParser(\.amount, parseMfactAmount, mandatoryArgPlaceholder: "[+|-]<number>"),
        ],
    )

    public var amount: Lateinit<MfactCmdArgs.Amount> = .uninitialized

    public enum Amount: Equatable, Sendable {
        case set(Double)
        case add(Double)
        case subtract(Double)
    }
}

public func parseMfactCmdArgs(_ args: StrArrSlice) -> ParsedCmd<MfactCmdArgs> {
    parseSpecificCmdArgs(MfactCmdArgs(rawArgs: args), args)
}

private func parseMfactAmount(i: ArgParserInput) -> ParsedCliArgs<MfactCmdArgs.Amount> {
    if let number = Double(i.arg.removePrefix("+").removePrefix("-")) {
        switch true {
            case i.arg.starts(with: "+"): .succ(.add(number), advanceBy: 1)
            case i.arg.starts(with: "-"): .succ(.subtract(number), advanceBy: 1)
            default: .succ(.set(number), advanceBy: 1)
        }
    } else {
        .fail("<number> argument must be a number", advanceBy: 1)
    }
}
