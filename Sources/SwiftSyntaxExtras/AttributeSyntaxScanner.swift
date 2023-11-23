import SwiftSyntax

public struct AttributeSyntaxScanner {

    public init(node: AttributeSyntax) {
        self.node = node
    }

    let node: AttributeSyntax

    // MARK: Labeled Arguments

    public func memberAccessArgument(with label: String) throws -> MemberAccessExprSyntax? {
        guard let argument = try labeledArgument(with: label) else {
            return nil
        }
        guard let memberAccessArgument = argument.expression.as(MemberAccessExprSyntax.self) else {
            throw SyntaxInternal(debugMessage: "Unexpected '\(label)' expression type: \(argument.expression).")
        }
        return memberAccessArgument
    }

    public func memberAccessArguments(with label: String) throws -> [MemberAccessExprSyntax]? {
        guard let arguments = try labeledArguments(with: label) else {
            return nil
        }
        let result = try arguments.map { labeledExprSyntax in
            guard let memberAccessExprSyntax = labeledExprSyntax.expression.as(MemberAccessExprSyntax.self) else {
                throw SyntaxInternal(debugMessage: "Unexpected '\(label)' expression type: \(labeledExprSyntax.expression).")
            }
            return memberAccessExprSyntax
        }
        return result
    }

    public func stringLiteralArgument(with label: String) throws -> String? {
        guard let argument = try labeledArgument(with: label) else {
            return nil
        }
        guard let stringLiteralArgument = argument.expression.as(StringLiteralExprSyntax.self) else {
            throw SyntaxInternal(debugMessage: "Unexpected '\(label)' expression type: \(argument.expression).")
        }
        guard let text = stringLiteralArgument.segments.firstToken(viewMode: .sourceAccurate)?.text else {
            throw SyntaxInternal(debugMessage: "Unexpected '\(label)' expression: '\(stringLiteralArgument)'.")
        }
        return text
    }

    private func labeledArgument(with label: String) throws -> LabeledExprSyntax? {
        guard let arguments = try labeledArguments(with: label) else {
            return nil
        }
        return arguments.first
    }

    /// Variadic arguments with a label.
    private func labeledArguments(with label: String) throws -> LabeledExprListSyntax? {
        guard let arguments = node.arguments else {
            // Ommitted arguments are allowed. This is same as omitted (default) labeled argument
            // or nil labeled argument below.
            return nil
        }
        guard let labeledExprListSyntax = arguments.as(LabeledExprListSyntax.self) else {
            throw SyntaxInternal(debugMessage: "Unexpected arguments type.")
        }
        // Handles variadics.
        guard case let filteredExprListSyntax = labeledExprListSyntax.drop(while: { $0.label.map { $0.text != label } ?? true }).prefix(while: { $0.label?.text == label || $0.label == nil }), !filteredExprListSyntax.isEmpty else {
            // Omitted argument for given label is allowed.
            return nil
        }
        guard !filteredExprListSyntax.first!.expression.is(NilLiteralExprSyntax.self) else {
            // Optioanl parameter is allowed and can be explicitly or default
            // `nil` (literal) - same behavior as omitted.
            return nil
        }
        return LabeledExprListSyntax(filteredExprListSyntax)
    }

    // MARK: TypeAccessModifier argument

    public func typeAccessModifier(withLabel label: String) throws -> TypeAccessModifier? {
        guard let argument = try memberAccessArgument(with: label) else {
            return nil
        }
        guard let rawValue = argument.memberName else {
            throw SyntaxInternal(debugMessage: "Unexpected member decl reference.")
        }
        guard let accessModifier = TypeAccessModifier(rawValue: rawValue) else {
            throw SyntaxInternal(debugMessage: "Unexpected access modifier: '\(rawValue)'.")
        }
        return accessModifier
    }
}
