public struct FocusCmdArgs: CmdArgs {
    /*conforms*/ public var commonState: CmdArgsCommonState
    fileprivate init(rawArgs: StrArrSlice) { self.commonState = .init(rawArgs) }
    public static let parser: CmdParser<Self> = cmdParser(
        kind: .focus,
        allowInConfig: true,
        help: focus_help_generated,
        flags: [
            "--ignore-floating": falseBoolFlag(\.floatingAsTiling),
            "--boundaries": SubArgParser(\.rawBoundaries, upcastSubArgParserFun(parseBoundaries)),
            "--boundaries-action": SubArgParser(\.rawBoundariesAction, upcastSubArgParserFun(parseBoundariesAction)),
            "--window-id": SubArgParser(\.windowId, upcastSubArgParserFun(parseUInt32SubArg)),
            "--index": SubArgParser(\.index, upcastSubArgParserFun(parseUInt32SubArg)),
        ],
        posArgs: [ArgParser(\.nextPrev, upcastArgParserFun(parseNextPrevArg))],
    )

    public var rawBoundaries: Boundaries? = nil // todo cover boundaries wrapping with tests
    public var rawBoundariesAction: WhenBoundariesCrossed? = nil
    public var index: UInt32? = nil
    public var nextPrev: NextPrev? = nil
    public var floatingAsTiling: Bool = true

    public init(rawArgs: StrArrSlice, nextPrev: NextPrev) {
        self.commonState = .init(rawArgs)
        self.nextPrev = nextPrev
    }

    public init(rawArgs: StrArrSlice, windowId: UInt32) {
        self.commonState = .init(rawArgs)
        self.windowId = windowId
    }

    public init(rawArgs: StrArrSlice, index: UInt32) {
        self.commonState = .init(rawArgs)
        self.index = index
    }

    public enum Boundaries: String, CaseIterable, Equatable, Sendable {
        case workspace
        case allMonitorsOuterFrame = "all-monitors-outer-frame"
    }
    public enum WhenBoundariesCrossed: String, CaseIterable, Equatable, Sendable {
        case stop = "stop"
        case fail = "fail"
        case wrapAroundTheWorkspace = "wrap-around-the-workspace"
        case wrapAroundAllMonitors = "wrap-around-all-monitors"
    }
}

public enum FocusCmdTarget {
    case windowId(UInt32)
    case index(UInt32)
    case relative(NextPrev)

    var isRelative: Bool {
        if case .relative = self {
            return true
        } else {
            return false
        }
    }
}

extension FocusCmdArgs {
    public var target: FocusCmdTarget {
        if let nextPrev {
            return .relative(nextPrev)
        }
        if let windowId {
            return .windowId(windowId)
        }
        if let index {
            return .index(index)
        }
        die("Parser invariants are broken")
    }

    public var boundaries: Boundaries { rawBoundaries ?? .workspace }
    public var boundariesAction: WhenBoundariesCrossed { rawBoundariesAction ?? .stop }
}

public func parseFocusCmdArgs(_ args: StrArrSlice) -> ParsedCmd<FocusCmdArgs> {
    return parseSpecificCmdArgs(FocusCmdArgs(rawArgs: args), args)
        .flatMap { (raw: FocusCmdArgs) -> ParsedCmd<FocusCmdArgs> in
            raw.boundaries == .workspace && raw.boundariesAction == .wrapAroundAllMonitors
                ? .failure("\(raw.boundaries.rawValue) and \(raw.boundariesAction.rawValue) is an invalid combination of values")
                : .cmd(raw)
        }
        .filter("Mandatory argument is missing. \(NextPrev.unionLiteral), --window-id or --index is required") {
            $0.nextPrev != nil || $0.windowId != nil || $0.index != nil
        }
        .filter("--window-id is incompatible with other options") {
            $0.windowId == nil || $0 == FocusCmdArgs(rawArgs: args, windowId: $0.windowId.orDie())
        }
        .filter("--index is incompatible with other options") {
            $0.index == nil || $0 == FocusCmdArgs(rawArgs: args, index: $0.index.orDie())
        }
        .filter("(next|prev) only supports --boundaries workspace") {
            $0.target.isRelative.implies($0.boundaries == .workspace)
        }
}

private func parseBoundariesAction(i: SubArgParserInput) -> ParsedCliArgs<FocusCmdArgs.WhenBoundariesCrossed> {
    if let arg = i.nonFlagArgOrNil() {
        return .init(parseEnum(arg, FocusCmdArgs.WhenBoundariesCrossed.self), advanceBy: 1)
    } else {
        return .fail("<action> is mandatory", advanceBy: 0)
    }
}

private func parseBoundaries(i: SubArgParserInput) -> ParsedCliArgs<FocusCmdArgs.Boundaries> {
    if let arg = i.nonFlagArgOrNil() {
        return .init(parseEnum(arg, FocusCmdArgs.Boundaries.self), advanceBy: 1)
    } else {
        return .fail("<boundary> is mandatory", advanceBy: 0)
    }
}
