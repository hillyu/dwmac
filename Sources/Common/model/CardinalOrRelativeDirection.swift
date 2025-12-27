public enum CardinalOrRelativeDirection: Equatable, Sendable {
    case direction(CardinalDirection)
    case relative(NextPrev)
}

extension CardinalOrRelativeDirection: CaseIterable {
    public static var allCases: [CardinalOrRelativeDirection] {
        CardinalDirection.allCases.map { .direction($0) } + NextPrev.allCases.map { .relative($0) }
    }
}

extension CardinalOrRelativeDirection: RawRepresentable {
    public typealias RawValue = String

    public init?(rawValue: RawValue) {
        if let d = CardinalDirection(rawValue: rawValue) {
            self = .direction(d)
        } else if let np = NextPrev(rawValue: rawValue) {
            self = .relative(np)
        } else {
            return nil
        }
    }

    public var rawValue: RawValue {
        return switch self {
            case .direction(let d): d.rawValue
            case .relative(let np): np.rawValue
        }
    }
}
