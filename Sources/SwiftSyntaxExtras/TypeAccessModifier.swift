import SwiftSyntax

public enum TypeAccessModifier: String {

    case `open`, `public`, `internal`, `fileprivate`, `private`

    static var `default`: Self { .internal }
 
    public static let parameterLabel: StaticString = "accessModifier"

    public var stringWithSpaceAfter: String { rawValue + " " }
}

public extension Optional where Wrapped == TypeAccessModifier {

    var stringWithSpaceAfter: String {
        switch self {
            case .none: ""
            case .some(let wrapped): wrapped.stringWithSpaceAfter
        }
    }
}

extension TypeAccessModifier: Comparable {

    /// More restrictive < more accessible.
    public static func < (lhs: TypeAccessModifier, rhs: TypeAccessModifier) -> Bool {
        lhs.rank < rhs.rank
    }

    private var rank: Int {
        switch self {
            case .open: 4
            case .public: 3
            case .internal: 2
            case .fileprivate: 1
            case .private: 0
        }
    }
}

/// Working with SwiftSyntax.
public extension TypeAccessModifier {

    init?(_ declModifierSyntax: DeclModifierSyntax) {
        switch declModifierSyntax.name.tokenKind {
            case .keyword(.open): self = .open
            case .keyword(.public): self = .public
            case .keyword(.internal): self = .internal
            case .keyword(.fileprivate): self = .fileprivate
            case .keyword(.private): self = .private
            default: return nil
        }
    }

    var keyword: Keyword {
        switch self {
            case .open: .open
            case .public: .public
            case .internal: .internal
            case .fileprivate: .fileprivate
            case .private: .private
        }
    }
}
