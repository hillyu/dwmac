import Common

public enum Layout: String, Sendable {
    case masterStack = "master-stack"
    case floating = "floating"
}

extension String {
    func parseLayout() -> Layout? {
        if self == "master-stack" {
            return .masterStack
        } else if self == "floating" {
            return .floating
        } else {
            return nil
        }
    }
}
