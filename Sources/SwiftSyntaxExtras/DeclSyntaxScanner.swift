import SwiftSyntax

public struct DeclSyntaxScanner {

    #warning("TODO: @WithBareCases")
    public enum DeclSyntaxType {
        case `enum`(EnumDeclSyntax)
        case `protocol`(ProtocolDeclSyntax)
        #warning("TODO: Delete after @WithBareCases")
        public var isEnum: Bool { if case .enum = self { true } else { false } }
        public var isProtocol: Bool { if case .protocol = self { true } else { false } }
    }

    public init(declSyntax: some DeclGroupSyntax, at node: AttributeSyntax) throws {
        if let value = declSyntax.as(EnumDeclSyntax.self) {
            self.declSyntax = .enum(value)
        } else if let value = declSyntax.as(ProtocolDeclSyntax.self) {
            self.declSyntax = .protocol(value)
        } else {
            throw Diagnostic.internal(debugMessage: "Incomplete implementation for \(declSyntax).").error(at: node)
        }
        self.node = node
    }

    public init(declSyntax: some DeclSyntaxProtocol, at node: AttributeSyntax) throws {
        if let value = declSyntax.as(EnumDeclSyntax.self) {
            self.declSyntax = .enum(value)
        } else if let value = declSyntax.as(ProtocolDeclSyntax.self) {
            self.declSyntax = .protocol(value)
        } else {
            throw Diagnostic.internal(debugMessage: "Incomplete implementation for \(declSyntax).").error(at: node)
        }
        self.node = node
    }

    public let declSyntax: DeclSyntaxType
    let node: AttributeSyntax

    public var name: String {
        get throws {
            switch declSyntax {
                case .enum(let value):
                    guard case .identifier(let name) = value.name.tokenKind else {
                        throw Diagnostic.internal(debugMessage: "Unexpected token kind: '\(value.name.tokenKind)'.").error(at: node)
                    }
                    return name
                case .protocol(let value):
                    guard case .identifier(let name) = value.name.tokenKind else {
                        throw Diagnostic.internal(debugMessage: "Unexpected token kind: '\(value.name.tokenKind)'.").error(at: node)
                    }
                    return name
            }
        }
    }

    public var typeAccessModifier: TypeAccessModifier? {
        switch declSyntax {
            case .enum(let value):
                value.modifiers.lazy.compactMap({ TypeAccessModifier($0) }).first
            case .protocol(let value):
                value.modifiers.lazy.compactMap({ TypeAccessModifier($0) }).first
        }
    }
}
