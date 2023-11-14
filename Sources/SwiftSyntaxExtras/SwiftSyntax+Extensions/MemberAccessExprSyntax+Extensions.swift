import SwiftSyntax

public extension MemberAccessExprSyntax {

    var typeName: String? {
        base?.as(DeclReferenceExprSyntax.self)?.baseName.text
    }

    var memberName: String? {
        declName.as(DeclReferenceExprSyntax.self)?.baseName.text
    }
}
