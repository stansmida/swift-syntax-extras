import Foundation
import SwiftDiagnostics
import SwiftSyntax

/// For unexpected, not yet implemented or otherwise invalid values when working with SwiftSyntax
/// that should emit via `DiagnosticMessage`.
public struct SyntaxInternal: Error, CustomStringConvertible, CustomDebugStringConvertible {

    public init(_ file: String = #file, _ line: Int = #line, debugMessage: String) {
        debugDescription = debugMessage
        description = "SyntaxInternal error at \(file):\(line)."
    }

    public let debugDescription: String
    public let description: String
}

public enum Diagnostic: DiagnosticMessage {

    /// See ``SyntaxInternal``.
    case `internal`(SyntaxInternal)
    /// Macro called with an invalid argument. E.g. corrupted name identifier, or access level more accessible
    /// than the attachee declaration.
    case invalidArgument(String)
    // Invalid declaration cases below generally means that the attached macro doesn't work with the declaration
    // that is being attached to.
    /// E.g. ``WithBareCases`` can be attached only to an enum with associated values.
    case invalidDeclaration(String)
    case invalidDeclarationType(any DeclSyntaxProtocol, expected: [DeclSyntaxProtocol.Type])
    case invalidDeclarationGroupType(any DeclGroupSyntax, expected: [DeclGroupSyntax.Type])
    case uncaughtError(Error)

    public var diagnosticID: SwiftDiagnostics.MessageID {
        switch self {
            case .internal:
                .init(domain: "\(Self.self)", id: "internal")
            case .invalidArgument:
                .init(domain: "\(Self.self)", id: "invalidArgument")
            case .invalidDeclaration, .invalidDeclarationType, .invalidDeclarationGroupType:
                .init(domain: "\(Self.self)", id: "invalidDeclaration")
            case .uncaughtError:
                .init(domain: "\(Self.self)", id: "uncaughtError")
        }
    }

    public var message: String {
        switch self {
            case .internal(let internalError):
                String(describing: internalError)
            case .invalidArgument(let message):
                message
            case .invalidDeclaration(let message):
                message
            case .invalidDeclarationType(let invalid, let expected):
                "This marco can be attached only to \(ListFormatter.localizedString(byJoining: expected.map { "\($0.self)" })), not \(invalid.kind)."
            case .invalidDeclarationGroupType(let invalid, let expected):
                "This marco can be attached only to \(ListFormatter.localizedString(byJoining: expected.map { "\($0.self)" })), not \(invalid.kind)."
            case .uncaughtError(let error):
                "'\(type(of: error))': \(error.localizedDescription)"
        }
    }

    public var severity: SwiftDiagnostics.DiagnosticSeverity {
        switch self {
            default: .error
        }
    }
}

public extension DiagnosticMessage {

    func error(at node: AttributeSyntax) -> DiagnosticsError {
        .init(diagnostics: [.init(node: node, message: self)])
    }
}

public extension Error {

    func diagnosticError(at node: AttributeSyntax) -> DiagnosticsError {
        if let diagnosticsError = self as? DiagnosticsError {
            diagnosticsError
        } else if let syntaxInternal = self as? SyntaxInternal {
            Diagnostic.internal(syntaxInternal).error(at: node)
        } else {
            Diagnostic.uncaughtError(self).error(at: node)
        }
    }
}
