//
//  RouterMacro.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 27/03/2026
//

import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct RouterMacro {
    /// Base name used when generating unique handler names.
    static let generatedHandlerName = "RouteHandler"

    static let routerAttributeName = "Router"
    static let routeHandlerAttributeName = "RouteHandler"
    static let middlewareAttributeName = "Middleware"
    static let disableParameterCheckAttributeName = "DisableParameterCheck"
    static let bypassMacroName = "Bypass"
    static let registerMacroName = "Register"
    static let forwardParametersMacroName = "ForwardParameters"
    static let webSocketMacroName = "WebSocket"
    static let webSocketDidUpgradeLabel = "didUpgrade"
    static let autoRegisterableAttributeName = "AutoRegisterable"
    static let typedPathAttributeName = "Path"
    static let typedQueryAttributeName = "Query"
    static let typedContentAttributeName = "ContentBody"

    /// Every freestanding route declaration macro supported by `@Router`.
    enum RouteMacroName: String {
        case on = "On"
        case get = "Get"
        case post = "Post"
        case put = "Put"
        case delete = "Delete"

        var defaultMethod: String? {
            switch self {
            case .on:
                return nil
            case .get:
                return "GET"
            case .post:
                return "POST"
            case .put:
                return "PUT"
            case .delete:
                return "DELETE"
            }
        }
    }

    /// WebSocket route events are modeled as marker macros inside the `#WebSocket` body.
    enum WebSocketEventMacroName: String {
        case onText = "OnText"
        case onBinary = "OnBinary"
        case onClose = "OnClose"

        var callbackExpression: String {
            switch self {
            case .onText:
                return "ws.onText"
            case .onBinary:
                return "ws.onBinary"
            case .onClose:
                return "ws.onClose.whenComplete"
            }
        }
    }

    /// Shared diagnostic domain so every Router-related error appears under one namespace.
    enum DiagnosticSeverity {
        static let domain = "VaporKit.RouterMacro"
    }

    /// Centralizes every user-facing diagnostic emitted while parsing or validating routes.
    enum RouteMacroDiagnostic: String, DiagnosticMessage {
        case requiresTrailingClosure = "Route macros only support trailing closures."
        case doesNotAcceptClosureReference = "Route macros do not accept closure references as arguments. Use a trailing closure and call the handler explicitly."
        case routeHandlerRequiresSingleRequestParameter = "@RouteHandler functions must accept exactly one parameter of type Request or Vapor.Request."
        case webSocketRequiresTrailingClosure = "#WebSocket only supports trailing closures."
        case webSocketOnlySupportsEventMacros = "#WebSocket bodies may only contain websocket event macros."
        case webSocketEventRequiresTrailingClosure = "WebSocket event macros only support trailing closures."
        case webSocketEventInvalidSignature = "#OnText and #OnBinary handlers must accept exactly two parameters."
        case webSocketCloseInvalidSignature = "#OnClose handlers must not declare parameters."
        case webSocketInvalidAdditionalClosureLabel = "#WebSocket only supports an additional trailing closure labeled didUpgrade:."
        case typedRouteRequiresRequestParameter = "Typed route functions must accept exactly one Request or Vapor.Request parameter."
        case typedRouteRequiresInjectedParameterAttribute = "Typed handler parameters after Request must be marked with @Path, @Query, or @ContentBody."
        case typedRoutePathRequiresLiteralName = "@Path requires a static string parameter name."
        case typedRouteQueryRequiresLiteralKey = "@Query requires a static string key."

        var message: String { rawValue }
        var diagnosticID: MessageID { .init(domain: DiagnosticSeverity.domain, id: "\(self)") }
        var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
    }

    struct ParameterCheckDiagnostic: DiagnosticMessage {
        enum Kind: String {
            case requiredParameterMissingFromRoute
            case dynamicParameterName
        }

        let kind: Kind
        let severity: SwiftDiagnostics.DiagnosticSeverity

        var message: String {
            switch kind {
            case .requiredParameterMissingFromRoute:
                return "Required path parameter is not declared in this route URL."
            case .dynamicParameterName:
                return "Getting a route parameter from a variable is unsafe for static checking. Use a string literal, or wrap the expression in #Bypass to silence this warning."
            }
        }

        var diagnosticID: MessageID {
            .init(domain: DiagnosticSeverity.domain, id: kind.rawValue)
        }
    }

    /// Fix-its stay close to the diagnostics that use them so edits remain discoverable.
    enum RouteMacroFixIt: String, FixItMessage {
        case moveClosureToTrailing = "Move closure to trailing closure"

        var message: String { rawValue }
        var fixItID: MessageID { .init(domain: DiagnosticSeverity.domain, id: "\(self)") }
    }

    /// Normalized representation of a freestanding route declaration like `#Get("users") { ... }`.
    struct FunctionMetadata {
        let path: String
        let method: String
        let middlewares: [ExprSyntax]
        let requestKeyword: String?
        let explicitReturnType: String?
        let parameterCheckOverride: StaticCheckOverride?
        let generatedRequestKeyword: TokenSyntax
        let content: CodeBlockItemListSyntax
        let innerName: TokenSyntax

        var resolvedRequestKeyword: String {
            requestKeyword ?? generatedRequestKeyword.text
        }

        var responseType: String {
            explicitReturnType ?? "some Vapor.AsyncResponseEncodable"
        }

        /// When the source closure used `$0`, generation rewrites it to the synthesized request name.
        var resolvedContent: CodeBlockItemListSyntax {
            guard requestKeyword == nil else {
                return content
            }

            let rewriter = ShorthandRequestRewriter(replacementIdentifier: resolvedRequestKeyword)
            return rewriter.rewrite(Syntax(content)).cast(CodeBlockItemListSyntax.self)
        }
    }

    /// Metadata for existing functions marked with `@RouteHandler`.
    struct HandlerMethodMetadata {
        let path: String
        let method: String
        let middlewares: [ExprSyntax]
        let requestKeyword: String
        let parameterCheckOverride: StaticCheckOverride?
        let body: CodeBlockSyntax?
        let functionName: TokenSyntax
    }

    /// Metadata for `@Get`/`@Post`/`@On` typed controller methods.
    struct TypedHandlerMethodMetadata {
        let path: String
        let method: String
        let middlewares: [ExprSyntax]
        let requestParameter: FunctionParameterMetadata
        let injectedParameters: [InjectedParameterMetadata]
        let pathParameters: [PathParameterMetadata]
        let parameterCheckOverride: StaticCheckOverride?
        let functionName: TokenSyntax
        let wrapperName: TokenSyntax
        let explicitReturnType: String?
        let isAsync: Bool
        let isThrowing: Bool

        var responseType: String {
            explicitReturnType ?? "some Vapor.AsyncResponseEncodable"
        }
    }

    struct FunctionParameterMetadata {
        let externalName: String?
        let localName: String
    }

    struct PathParameterMetadata {
        let externalName: String?
        let localName: String
        let pathName: String
        let type: TypeSyntax
        let generatedName: TokenSyntax
        let pathAttribute: AttributeSyntax
    }

    struct InjectedParameterMetadata {
        let externalName: String?
        let localName: String
        let type: TypeSyntax
        let defaultValue: ExprSyntax?
        let generatedName: TokenSyntax
        let source: InjectedParameterSource
    }

    enum InjectedParameterSource {
        case path(name: String)
        case query(keyPath: [String]?)
        case content
    }

    /// A child `RouteCollection` registration declared with `#Register(...)`.
    struct RegisteredRouterMetadata {
        let routers: [ExprSyntax]
        let routerPrefix: String?
    }

    /// Normalized representation of a websocket route declaration and its event registrations.
    struct WebSocketMetadata {
        let path: String
        let middlewares: [ExprSyntax]
        let maxFrameSize: ExprSyntax?
        let shouldUpgrade: ShouldUpgradeMetadata?
        let events: [WebSocketEventMetadata]
        let innerName: TokenSyntax
        let shouldUpgradeName: TokenSyntax?
    }

    struct WebSocketEventMetadata {
        let kind: WebSocketEventMacroName
        let closure: ClosureExprSyntax
        let shorthandBody: CodeBlockItemListSyntax?
        let generatedWebSocketKeyword: TokenSyntax?
        let generatedPayloadKeyword: TokenSyntax?
    }

    struct ShouldUpgradeMetadata {
        let expression: ExprSyntax
        let requestKeyword: String?
        let body: CodeBlockItemListSyntax?
        let generatedRequestKeyword: TokenSyntax

        var resolvedRequestKeyword: String {
            requestKeyword ?? generatedRequestKeyword.text
        }
    }

    /// A single `req.parameters.require/get("...")` access discovered inside handler code.
    struct RequiredParameterAccess {
        let syntax: Syntax
        let name: String?
        let override: StaticCheckOverride?
    }

    enum StaticCheckOverride {
        case error
        case warning
    }

    /// Rewrites closure shorthand access so generated handlers can use a stable parameter name.
    final class ShorthandRequestRewriter: SyntaxRewriter {
        private let replacementIdentifier: String

        init(replacementIdentifier: String) {
            self.replacementIdentifier = replacementIdentifier
        }

        override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
            guard node.baseName.text == "$0" else {
                return super.visit(node)
            }

            // The generated handler always receives a named request parameter, never shorthand.
            return ExprSyntax(
                DeclReferenceExprSyntax(baseName: .identifier(replacementIdentifier))
            )
        }
    }

    /// Rewrites websocket event shorthand arguments into generated callback parameter names.
    final class WebSocketEventShorthandRewriter: SyntaxRewriter {
        private let webSocketIdentifier: String
        private let payloadIdentifier: String

        init(webSocketIdentifier: String, payloadIdentifier: String) {
            self.webSocketIdentifier = webSocketIdentifier
            self.payloadIdentifier = payloadIdentifier
        }

        override func visit(_ node: DeclReferenceExprSyntax) -> ExprSyntax {
            switch node.baseName.text {
            case "$0":
                return ExprSyntax(
                    DeclReferenceExprSyntax(baseName: .identifier(webSocketIdentifier))
                )
            case "$1":
                return ExprSyntax(
                    DeclReferenceExprSyntax(baseName: .identifier(payloadIdentifier))
                )
            default:
                return super.visit(node)
            }
        }
    }

    /// Collects `req.parameters.require/get("...")` accesses for a given request identifier.
    final class RequiredParameterVisitor: SyntaxVisitor {
        private let acceptedRequestNames: Set<String>
        private var bypassStack: [StaticCheckOverride] = []
        private(set) var requiredParameters: [RequiredParameterAccess] = []
        private(set) var dynamicParameterAccesses: [Syntax] = []

        init(acceptedRequestNames: Set<String>) {
            self.acceptedRequestNames = acceptedRequestNames
            super.init(viewMode: .sourceAccurate)
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            // Nested closures introduce their own scopes and can shadow `req`, so the validator
            // intentionally treats them as unrelated code and skips their bodies.
            .skipChildren
        }

        override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
            guard node.macroName.text == bypassMacroName else {
                return .visitChildren
            }

            switch RouterMacro.staticCheckOverride(from: node) {
            case .error:
                // `#Bypass` marks a region that syntax-only validation passes should leave untouched.
                return .skipChildren
            case .warning:
                bypassStack.append(.warning)
                if let trailingClosure = node.trailingClosure {
                    walk(Syntax(trailingClosure.statements))
                }
                _ = bypassStack.popLast()
                return .skipChildren
            }
        }

        override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
            if let access = requiredParameterAccess(from: node) {
                switch (access.name, bypassStack.last) {
                case (.some, _):
                    requiredParameters.append(
                        .init(
                            syntax: access.syntax,
                            name: access.name,
                            override: bypassStack.last
                        )
                    )
                case (.none, .warning):
                    break
                case (.none, _):
                    dynamicParameterAccesses.append(access.syntax)
                }
            }

            return .visitChildren
        }

        private func requiredParameterAccess(from call: FunctionCallExprSyntax) -> RequiredParameterAccess? {
            guard let calledMember = call.calledExpression.as(MemberAccessExprSyntax.self),
                  (
                    calledMember.declName.baseName.text == "get" ||
                    calledMember.declName.baseName.text == "require"
                  ),
                  let parametersAccess = calledMember.base?.as(MemberAccessExprSyntax.self),
                  parametersAccess.declName.baseName.text == "parameters",
                  let requestReference = parametersAccess.base?.as(DeclReferenceExprSyntax.self),
                  acceptedRequestNames.contains(requestReference.baseName.text),
                  let firstArgument = call.arguments.first
            else {
                return nil
            }

            // Only literal parameter names participate in compile-time validation.
            return .init(
                syntax: Syntax(call),
                name: RouterMacro.stringLiteralValue(from: firstArgument.expression),
                override: nil
            )
        }
    }
}
