import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import XCTest

#if canImport(VaporKitMacros)
@testable import VaporKitMacros

final class MacroHelperCoverageTests: XCTestCase {
    func testCompilerPluginRegistersAllMacros() {
        let plugin = VaporkitPlugin()
        let macroNames = plugin.providingMacros.map { String(describing: $0) }

        XCTAssertEqual(
            macroNames,
            [
                String(describing: RouterMacro.self),
                String(describing: ValidatableMacro.self),
                String(describing: BypassMacro.self),
                String(describing: EmptyMacro.self),
                String(describing: EmptyExpressionMacro.self),
            ]
        )
    }

    func testDiagnosticIdentifiersExposeStableDomains() {
        let validatableID = ValidatableMacro.MacroDiagnostic.constraintRequiresRule.diagnosticID
        XCTAssertFalse(String(reflecting: validatableID).isEmpty)

        let bypassID = BypassMacro.BypassDiagnostic.requiresTrailingClosure.diagnosticID
        XCTAssertFalse(String(reflecting: bypassID).isEmpty)
    }

    func testValidatableRuleHelpersHandleOptionalSpellings() {
        XCTAssertEqual(
            ValidatableMacro.propertyKind(for: TypeSyntax(stringLiteral: "String!")),
            .init(baseTypeName: "String", isOptional: true)
        )
        XCTAssertEqual(
            ValidatableMacro.propertyKind(for: TypeSyntax(stringLiteral: "Optional<Int>")),
            .init(baseTypeName: "Int", isOptional: true)
        )
        XCTAssertTrue(
            ValidatableMacro.isRuleSupported(
                "nil",
                propertyKind: .init(baseTypeName: "String", isOptional: true)
            )
        )
        XCTAssertTrue(
            ValidatableMacro.isRuleSupported(
                "in",
                propertyKind: .init(baseTypeName: "Int", isOptional: false)
            )
        )
        XCTAssertNil(ValidatableMacro.validatingTypeSyntax(from: ExprSyntax(stringLiteral: ".self")))
    }

    func testRouterHelpersHandleQualifiedAttributesAndUnderscoredRequestNames() throws {
        let function = try XCTUnwrap(
            FunctionDeclSyntax(
                """
                @Demo.Middleware(AuthMiddleware())
                @Demo.RouteHandler("users", ":id", method: .GET)
                func show(_ req: Vapor.Request) -> Bool {
                    true
                }
                """
            )
        )

        let routeAttribute = try XCTUnwrap(RouterMacro.routeHandlerAttribute(from: function.attributes))
        XCTAssertEqual(RouterMacro.attributeName(of: routeAttribute), "RouteHandler")
        XCTAssertEqual(RouterMacro.routeHandlerRequestKeyword(from: function.signature), "req")
        XCTAssertEqual(
            RouterMacro.middlewareExpressions(from: function.attributes).map(\.trimmedDescription),
            ["AuthMiddleware()"]
        )
        XCTAssertTrue(RouterMacro.isSupportedRouteHandlerSignature(function.signature))
        XCTAssertEqual(RouterMacro.routeSpec(from: routeAttribute).path, "users/:id")
        XCTAssertEqual(RouterMacro.routeSpec(from: routeAttribute).method, "GET")
    }

    func testRouterHelpersRejectInvalidSignaturesAndMissingPrefixArguments() throws {
        let invalidFunction = try FunctionDeclSyntax(
            """
            func show(req: Request, slug: String) -> Bool {
                true
            }
            """
        )
        let emptyFunction = try FunctionDeclSyntax(
            """
            func show() -> Bool {
                true
            }
            """
        )
        let routerAttribute = AttributeSyntax("@Router")

        XCTAssertFalse(RouterMacro.isSupportedRouteHandlerSignature(invalidFunction.signature))
        XCTAssertFalse(RouterMacro.isSupportedRouteHandlerSignature(emptyFunction.signature))
        XCTAssertNil(RouterMacro.routerPrefix(from: routerAttribute))
    }
}
#endif
