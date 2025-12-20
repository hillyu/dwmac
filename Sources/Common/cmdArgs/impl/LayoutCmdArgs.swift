public struct LayoutCmdArgs: CmdArgs {
    /*conforms*/ public var commonState: CmdArgsCommonState
    fileprivate init(rawArgs: StrArrSlice) { self.commonState = .init(rawArgs) }
    public static let parser: CmdParser<Self> = cmdParser(
        kind: .layout,
        allowInConfig: true,
        help: layout_help_generated,
        flags: [
            "--window-id": optionalWindowIdFlag(),
        ],
        posArgs: [newArgParser(\.toggleBetween, parseToggleBetween, mandatoryArgPlaceholder: LayoutDescription.unionLiteral)],
    )

    public var toggleBetween: Lateinit<[LayoutDescription]> = .uninitialized

    public init(rawArgs: [String], toggleBetween: [LayoutDescription]) {
        self.commonState = .init(rawArgs.slice)
        self.toggleBetween = .initialized(toggleBetween)
    }

    public enum LayoutDescription: String, CaseIterable, Equatable, Sendable {
        case master_stack = "master-stack"
        case horizontal, vertical
        case h_master_stack = "h_master-stack", v_master_stack = "v_master-stack"
        case tiling, floating
    }
}

private func parseToggleBetween(input: ArgParserInput) -> ParsedCliArgs<[LayoutCmdArgs.LayoutDescription]> {
    let args = input.nonFlagArgs()

    var result: [LayoutCmdArgs.LayoutDescription] = []
    var i = 0
    for arg in args {
        if let layout = arg.parseLayoutDescription() {
            result.append(layout)
        } else {
            return .fail(
                "Can't parse '\(arg)'\nPossible values: \(LayoutCmdArgs.LayoutDescription.unionLiteral)",
                advanceBy: i + 1,
            )
        }
        i += 1
    }

    return .succ(result, advanceBy: args.count)
}

public func parseLayoutCmdArgs(_ args: StrArrSlice) -> ParsedCmd<LayoutCmdArgs> {
    parseSpecificCmdArgs(LayoutCmdArgs(rawArgs: args), args).map {
        check(!$0.toggleBetween.val.isEmpty)
        return $0
    }
}

extension String {
    fileprivate func parseLayoutDescription() -> LayoutCmdArgs.LayoutDescription? {
        if let parsed = LayoutCmdArgs.LayoutDescription(rawValue: self) {
            return parsed
        } else if self == "master-stack" {
            return .master_stack
        } else if self == "h_master-stack" {
            return .h_master_stack
        } else if self == "v_master-stack" {
            return .v_master_stack
        }
        return nil
    }
}
