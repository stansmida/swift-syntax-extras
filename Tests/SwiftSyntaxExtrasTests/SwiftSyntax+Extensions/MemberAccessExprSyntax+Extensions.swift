import SwiftParser
import SwiftSyntax
import SwiftSyntaxExtras
import XCTest

final class MemberAccessExprSyntaxTests: XCTestCase {

    func testMemberAccessExpr() throws {
        let fullSelf = memberAccessExprSyntax("Foo.self")
        XCTAssertEqual(fullSelf.typeName, "Foo")
        XCTAssertEqual(fullSelf.memberName, "self")
        let fullBar = memberAccessExprSyntax("Foo.bar")
        XCTAssertEqual(fullBar.typeName, "Foo")
        XCTAssertEqual(fullBar.memberName, "bar")
        let member = memberAccessExprSyntax(".bar")
        XCTAssertNil(member.typeName)
        XCTAssertEqual(member.memberName, "bar")
    }

    // MARK: Utils

    func memberAccessExprSyntax(_ string: String) -> MemberAccessExprSyntax {
        let source = """
        @SomeMacro(\(string))
        struct SomeType {}
        """
        let sourceFileSyntax = Parser.parse(source:source)
        return sourceFileSyntax.statements.first!.as(CodeBlockItemSyntax.self)!.item.as(StructDeclSyntax.self)!.attributes.first!.as(AttributeSyntax.self)!.arguments!.as(LabeledExprListSyntax.self)!.first!.expression.as(MemberAccessExprSyntax.self)!
    }
}
