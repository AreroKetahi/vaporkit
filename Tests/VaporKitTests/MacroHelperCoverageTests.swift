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
                String(describing: OpenAPISchemaMacro.self),
            ]
        )
    }

    @Test func diagnosticIdentifiersExposeStableDomains() {
        let validatableID = ValidatableMacro.MacroDiagnostic.constraintRequiresRule.diagnosticID
        #expect(!String(reflecting: validatableID).isEmpty)

        let bypassID = BypassMacro.BypassDiagnostic.requiresTrailingClosure.diagnosticID
        #expect(!String(reflecting: bypassID).isEmpty)
    }

    @Test func openAPISchemaTypesQualifyNestedTypesInsideGenericContainers() throws {
        let declaration = try StructDeclSyntax(
            """
            struct ProjectRouter {
                struct Filter {}
                struct UpdateBody {}
            }
            """
        )

        #expect(
            RouterMacro.openAPISchemaTypeDescription(
                TypeSyntax(stringLiteral: "[Filter?]"),
                in: declaration,
                routerIdentifier: "ProjectRouter"
            )
            == "[ProjectRouter.Filter?]"
        )
        #expect(
            RouterMacro.openAPISchemaTypeDescription(
                TypeSyntax(stringLiteral: "[String: UpdateBody]"),
                in: declaration,
                routerIdentifier: "ProjectRouter"
            )
            == "[String: ProjectRouter.UpdateBody]"
        )
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

    @Test func routerPathInterpolationPreservesParameterStrategies() throws {
        let attribute = AttributeSyntax(
            #"@Get("/users/\("id", decoding: UUID.self)/pages/\("page", converting: Int.self)/\(key: "slug")")"#
        )

        let spec = RouterMacro.routeSpec(from: attribute, macroName: .get)
        #expect(spec.path == "users/:id/pages/:page/:slug")

        guard case .decoding(type: "UUID") = spec.pathParameterStrategies["id"] else {
            Issue.record("Expected UUID decoding strategy")
            return
        }
        guard case .converting(type: "Int") = spec.pathParameterStrategies["page"] else {
            Issue.record("Expected Int conversion strategy")
            return
        }
        guard case .label = spec.pathParameterStrategies["slug"] else {
            Issue.record("Expected an untyped path label")
            return
        }
    }

    @Test func routerPathStrategiesSelectTheirExtractionBehavior() {
        let parameter = RouterMacro.InjectedParameterMetadata(
            externalName: nil,
            localName: "id",
            type: TypeSyntax(stringLiteral: "UUID"),
            defaultValue: nil,
            generatedName: .identifier("decodedID"),
            source: .path(name: "id")
        )

        #expect(
            RouterMacro.injectedParameterExtraction(
                parameter,
                pathParameterStrategies: ["id": .decoding(type: "UUID")],
                requestLocalName: "req"
            )
            == #"let decodedID = try req.parameters.decode("id", as: UUID.self)"#
        )
        #expect(
            RouterMacro.injectedParameterExtraction(
                parameter,
                pathParameterStrategies: ["id": .converting(type: "UUID")],
                requestLocalName: "req"
            )
            == #"let decodedID = try req.parameters.require("id", as: UUID.self)"#
        )
        #expect(
            RouterMacro.injectedParameterExtraction(
                parameter,
                pathParameterStrategies: ["id": .label],
                requestLocalName: "req"
            )
            == #"let decodedID = try req.parameters.require("id", as: UUID.self)"#
        )
    }

    @Test func routerPathParserRejectsInvalidParameterNames() {
        let dynamic = RouterMacro.parsedRouterPath(
            from: ExprSyntax(#""/users/\(key: dynamicKey)""#)
        )
        #expect(dynamic.diagnostics.map(\.message) == [.routerPathRequiresLiteralName])

        let invalid = RouterMacro.parsedRouterPath(
            from: ExprSyntax(#""/users/\(key: "")/\(key: "a/b")""#)
        )
        #expect(
            invalid.diagnostics.map(\.message)
            == [.routerPathEmptyName, .routerPathInvalidName]
        )

        let duplicate = RouterMacro.parsedRouterPath(
            from: ExprSyntax(#""/users/\(key: "id")/\("id", decoding: UUID.self)""#)
        )
        #expect(duplicate.diagnostics.map(\.message) == [.routerPathDuplicateName])
    }
}
#endif
