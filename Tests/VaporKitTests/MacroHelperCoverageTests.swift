import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import Testing

#if canImport(VaporKitMacros)
@testable import VaporKitMacros

@Suite
struct MacroHelperCoverageTests {
    @Test func compilerPluginRegistersAllMacros() {
        let plugin = VaporkitPlugin()
        let macroNames = plugin.providingMacros.map { String(describing: $0) }

        #expect(
            macroNames
            ==
            [
                String(describing: RouterMacro.self),
                String(describing: ValidatableMacro.self),
                String(describing: BypassMacro.self),
                String(describing: EmptyMacro.self),
                String(describing: EmptyExpressionMacro.self),
            ]
        )
    }

    @Test func diagnosticIdentifiersExposeStableDomains() {
        let validatableID = ValidatableMacro.MacroDiagnostic.constraintRequiresRule.diagnosticID
        #expect(!String(reflecting: validatableID).isEmpty)

        let bypassID = BypassMacro.BypassDiagnostic.requiresTrailingClosure.diagnosticID
        #expect(!String(reflecting: bypassID).isEmpty)
    }

    @Test func validatableRuleHelpersHandleOptionalSpellings() {
        #expect(
            ValidatableMacro.propertyKind(for: TypeSyntax(stringLiteral: "String!"))
            ==
            .init(baseTypeName: "String", isOptional: true)
        )
        #expect(
            ValidatableMacro.propertyKind(for: TypeSyntax(stringLiteral: "Optional<Int>"))
            ==
            .init(baseTypeName: "Int", isOptional: true)
        )
        #expect(
            ValidatableMacro.isRuleSupported(
                "nil",
                propertyKind: .init(baseTypeName: "String", isOptional: true)
            )
        )
        #expect(
            ValidatableMacro.isRuleSupported(
                "in",
                propertyKind: .init(baseTypeName: "Int", isOptional: false)
            )
        )
        #expect(ValidatableMacro.validatingTypeSyntax(from: ExprSyntax(stringLiteral: ".self")) == nil)
    }

    @Test func routerHelpersHandleQualifiedAttributesAndUnderscoredRequestNames() throws {
        let function = try FunctionDeclSyntax(
                """
                @Demo.Middleware(AuthMiddleware())
                @Demo.RouteHandler("users", ":id", method: .GET)
                func show(_ req: Vapor.Request) -> Bool {
                    true
                }
                """
        )

        let routeAttribute = try #require(RouterMacro.routeHandlerAttribute(from: function.attributes))
        #expect(RouterMacro.attributeName(of: routeAttribute) == "RouteHandler")
        #expect(RouterMacro.routeHandlerRequestKeyword(from: function.signature) == "req")
        #expect(
            RouterMacro.middlewareExpressions(from: function.attributes).map(\.trimmedDescription)
            ==
            ["AuthMiddleware()"]
        )
        #expect(RouterMacro.isSupportedRouteHandlerSignature(function.signature))
        #expect(RouterMacro.routeSpec(from: routeAttribute).path == "users/:id")
        #expect(RouterMacro.routeSpec(from: routeAttribute).method == "GET")
    }

    @Test func routerHelpersRejectInvalidSignaturesAndMissingPrefixArguments() throws {
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

        #expect(!RouterMacro.isSupportedRouteHandlerSignature(invalidFunction.signature))
        #expect(!RouterMacro.isSupportedRouteHandlerSignature(emptyFunction.signature))
        #expect(RouterMacro.routerPrefix(from: routerAttribute) == nil)
    }
}
#endif
