import SwiftSyntax

// MARK: - AccessLevel

public enum AccessLevel: String, Comparable {

    case `open`
    case `public`
    case `package`
    case `internal`
    case internalSet = "internal(set)"
    case `fileprivate`
    case fileprivateSet = "fileprivate(set)"
    case `private`
    case privateSet = "private(set)"

    /// More restrictive < more accessible.
    public static func < (lhs: AccessLevel, rhs: AccessLevel) -> Bool {
        lhs.rank < rhs.rank
    }

    private var rank: Int {
        switch self {
            case .`open`:           8
            case .`public`:         7
            case .`package`:        6
            case .`internal`:       5
            case .internalSet:      4
            case .`fileprivate`:    3
            case .fileprivateSet:   2
            case .`private`:        1
            case .privateSet:       0
        }
    }
}

/// Working with SwiftSyntax.
public extension AccessLevel {

    init?(_ declModifierSyntax: DeclModifierSyntax) throws {
        switch declModifierSyntax.name.tokenKind {
            case .keyword(.open):
                self = .open
            case .keyword(.public): 
                self = .public
            case .keyword(.package):
                self = .package
            case .keyword(.internal):
                self = try Self.hasSetDetail(declModifierSyntax) ? .internalSet : .internal
            case .keyword(.fileprivate): 
                self = try Self.hasSetDetail(declModifierSyntax) ? .fileprivateSet : .fileprivate
            case .keyword(.private):
                self = try Self.hasSetDetail(declModifierSyntax) ? .privateSet : .private
            default:
                return nil
        }
    }

    // TODO: Consider typed throws(SyntaxInternal) once it is available.
    private static func hasSetDetail(_ declModifierSyntax: DeclModifierSyntax) throws -> Bool {
        if declModifierSyntax.detail == nil {
            false
        } else if case .identifier("set") = declModifierSyntax.detail?.detail.tokenKind {
            true
        } else {
            throw SyntaxInternal(debugMessage: "Unexpected `DeclModifierSyntax.detail`.")
        }
    }
}


// MARK: - TypeAccessModifier

public enum TypeAccessModifier: String {

    case `open`, `public`, `package`, `internal`, `fileprivate`, `private`

    public static var `default`: Self { .internal }

    /// "Soft defalut" member acceess level of the type access level.
    public var memberDerivate: AccessLevel {
        self == .private ? .fileprivate : accessLevel
    }
}

extension TypeAccessModifier: Comparable {

    /// More restrictive < more accessible.
    public static func < (lhs: TypeAccessModifier, rhs: TypeAccessModifier) -> Bool {
        lhs.accessLevel < rhs.accessLevel
    }
}

public extension TypeAccessModifier {

    init?(_ declModifierSyntax: DeclModifierSyntax) throws {
        guard let accessLevel = try AccessLevel(declModifierSyntax) else {
            return nil
        }
        self.init(accessLevel)
    }

    init?(_ accessLevel: AccessLevel) {
        self.init(rawValue: accessLevel.rawValue)
    }

    var accessLevel: AccessLevel { AccessLevel(rawValue: rawValue)! }
}

public extension TypeAccessModifier {

    init?(withLabel label: String, in declSyntax: some DeclSyntaxProtocol, at node: AttributeSyntax) throws {
        let explicit = try AttributeSyntaxScanner(node: node).typeAccessModifier(withLabel: label)
        let implicit = try DeclSyntaxScanner(declSyntax: declSyntax).typeAccessModifier
        guard let result = try Self.make(explicit: explicit, implicit: implicit, at: node) else {
            return nil
        }
        self = result
    }

    init?(withLabel label: String, in declSyntax: some DeclGroupSyntax, at node: AttributeSyntax) throws {
        let explicit = try AttributeSyntaxScanner(node: node).typeAccessModifier(withLabel: label)
        let implicit = try DeclSyntaxScanner(declSyntax: declSyntax).typeAccessModifier
        guard let result = try Self.make(explicit: explicit, implicit: implicit, at: node) else {
            return nil
        }
        self = result
    }

    private static func make(explicit: TypeAccessModifier?, implicit: TypeAccessModifier?, at node: AttributeSyntax) throws -> TypeAccessModifier? {
        if let explicit {
            guard explicit <= (implicit ?? .default) else {
                throw Diagnostic.invalidArgument("Expansion type cannot have less restrictive access than its anchor declaration.").error(at: node)
            }
        }
        return explicit ?? implicit
    }
}
