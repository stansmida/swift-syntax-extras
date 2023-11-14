import SwiftParser
import SwiftSyntax
import SwiftSyntaxExtras
import XCTest

final class AttributeSyntaxScannerTests: XCTestCase {

    func testStringLiteralArgument() throws {
        XCTAssertEqual(
            try AttributeSyntaxScanner(node: attributeSyntax("@SomeMacro(x, a: x, foo: \"bar\")")).stringLiteralArgument(with: "foo"),
            "bar"
        )
    }

    func testMemberAccessArgument_notNil() throws {
        let syntax = attributeSyntax("@SomeMacro(.a, a: nil, foo: .bar)")
        let scanner = AttributeSyntaxScanner(node: syntax)
        let fooMember = try scanner.memberAccessArgument(with: "foo")
        XCTAssertNotNil(fooMember)
    }

    func testMemberAccessArgument_noArguments_nil() throws {
        let syntax = attributeSyntax("@SomeMacro")
        let scanner = AttributeSyntaxScanner(node: syntax)
        let member = try scanner.memberAccessArgument(with: "foo")
        XCTAssertNil(member)
    }

    func testMemberAccessArgument_emptyArguments_nil() throws {
        let syntax = attributeSyntax("@SomeMacro()")
        let scanner = AttributeSyntaxScanner(node: syntax)
        let member = try scanner.memberAccessArgument(with: "foo")
        XCTAssertNil(member)
    }

    func testMemberAccessArgument_nilArgument_nil() throws {
        let syntax = attributeSyntax("@SomeMacro(foo: nil)")
        let scanner = AttributeSyntaxScanner(node: syntax)
        let member = try scanner.memberAccessArgument(with: "foo")
        XCTAssertNil(member)
    }

    func testMemberAccessArgument_noMatch_nil() throws {
        let syntax = attributeSyntax("@SomeMacro(a: \"a\")")
        let scanner = AttributeSyntaxScanner(node: syntax)
        let member = try scanner.memberAccessArgument(with: "foo")
        XCTAssertNil(member)
    }

    func testMemberAccessArguments_solo_notNil() throws {
        let syntax = attributeSyntax("@SomeMacro(foo: .bar, .baz, .tic)")
        let scanner = AttributeSyntaxScanner(node: syntax)
        let fooMembers = try scanner.memberAccessArguments(with: "foo")
        XCTAssertEqual(fooMembers?.count, 3)
    }

    func testMemberAccessArguments_leading_notNil() throws {
        let syntax = attributeSyntax("@SomeMacro(foo: .bar, .baz, .tic, sthElse: c, a, another: .self)")
        let scanner = AttributeSyntaxScanner(node: syntax)
        let fooMembers = try scanner.memberAccessArguments(with: "foo")
        XCTAssertEqual(fooMembers?.count, 3)
    }

    func testMemberAccessArguments_middle_notNil() throws {
        let syntax = attributeSyntax("@SomeMacro(x, a: x, foo: .bar, .baz, .tic, sthElse: c)")
        let scanner = AttributeSyntaxScanner(node: syntax)
        let fooMembers = try scanner.memberAccessArguments(with: "foo")
        XCTAssertEqual(fooMembers?.count, 3)
    }

    func testMemberAccessArguments_trailing_notNil() throws {
        let syntax = attributeSyntax("@SomeMacro(x, a: x, foo: .bar, .baz)")
        let scanner = AttributeSyntaxScanner(node: syntax)
        let fooMembers = try scanner.memberAccessArguments(with: "foo")
        XCTAssertEqual(fooMembers?.count, 2)
    }

    // MARK: Utils

    func attributeSyntax(_ attribute: String) -> AttributeSyntax {
        let source = """
        \(attribute)
        struct SomeType {}
        """
        let sourceFileSyntax = Parser.parse(source:source)
        return sourceFileSyntax.statements.first!.as(CodeBlockItemSyntax.self)!.item.as(StructDeclSyntax.self)!.attributes.first!.as(AttributeSyntax.self)!
    }
}
