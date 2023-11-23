import SwiftSyntax

public struct DeclSyntaxScanner {

    public enum DeclSyntaxType {
        case `enum`(EnumDeclSyntax)
        case `protocol`(ProtocolDeclSyntax)

        public var isEnum: Bool { if case .enum = self { true } else { false } }
        public var isProtocol: Bool { if case .protocol = self { true } else { false } }
    }

    public init(declSyntax: some DeclGroupSyntax) throws {
        if let value = declSyntax.as(EnumDeclSyntax.self) {
            type = .enum(value)
        } else if let value = declSyntax.as(ProtocolDeclSyntax.self) {
            type = .protocol(value)
        } else {
            throw SyntaxInternal(debugMessage: "Incomplete implementation for \(declSyntax).")
        }
    }

    public init(declSyntax: some DeclSyntaxProtocol) throws {
        if let value = declSyntax.as(EnumDeclSyntax.self) {
            type = .enum(value)
        } else if let value = declSyntax.as(ProtocolDeclSyntax.self) {
            type = .protocol(value)
        } else {
            throw SyntaxInternal(debugMessage: "Incomplete implementation for \(declSyntax).")
        }
    }

    public let type: DeclSyntaxType

    public var name: String {
        get throws {
            switch type {
                case .enum(let value):
                    guard case .identifier(let name) = value.name.tokenKind else {
                        throw SyntaxInternal(debugMessage: "Unexpected token kind: '\(value.name.tokenKind)'.")
                    }
                    return name
                case .protocol(let value):
                    guard case .identifier(let name) = value.name.tokenKind else {
                        throw SyntaxInternal(debugMessage: "Unexpected token kind: '\(value.name.tokenKind)'.")
                    }
                    return name
            }
        }
    }

    public var typeAccessModifier: TypeAccessModifier? {
        get throws {
            switch type {
                case .enum(let value):
                    try value.modifiers.lazy.compactMap({ try TypeAccessModifier($0) }).first
                case .protocol(let value):
                    try value.modifiers.lazy.compactMap({ try TypeAccessModifier($0) }).first
            }
        }
    }
}
