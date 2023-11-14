import SwiftSyntax

public enum TypeAccessModifier: String {

    case `open`, `public`, `internal`, `fileprivate`, `private`

    static var `default`: Self { .internal }
 
    #warning("either it can be passed or change to string")
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

public extension TypeAccessModifier {

    init?(declSyntax: some DeclSyntaxProtocol, at node: AttributeSyntax) throws {
        let explicit = try AttributeSyntaxScanner(node: node).typeAccessModifier
        let implicit = try DeclSyntaxScanner(declSyntax: declSyntax, at: node).typeAccessModifier
        guard let result = try Self.make(explicit: explicit, implicit: implicit, at: node) else {
            return nil
        }
        self = result
    }

    init?(declSyntax: some DeclGroupSyntax, at node: AttributeSyntax) throws {
        let explicit = try AttributeSyntaxScanner(node: node).typeAccessModifier
        let implicit = try DeclSyntaxScanner(declSyntax: declSyntax, at: node).typeAccessModifier
        guard let result = try Self.make(explicit: explicit, implicit: implicit, at: node) else {
            return nil
        }
        self = result
    }

    private static func make(explicit: TypeAccessModifier?, implicit: TypeAccessModifier?, at node: AttributeSyntax) throws -> TypeAccessModifier? {
        if let explicit {
            guard explicit <= (implicit ?? .internal) else {
                throw Diagnostic.invalidArgument("Expansion type cannot have less restrictive access than its anchor declaration.").error(at: node)
            }
        }
        return explicit ?? implicit
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
