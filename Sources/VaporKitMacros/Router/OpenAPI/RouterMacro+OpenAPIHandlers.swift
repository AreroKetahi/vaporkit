//
//  RouterMacro+OpenAPIHandlers.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 27/03/2026
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

extension RouterMacro {

    static func openAPIHandlerExpressions(
        in declaration: any DeclGroupSyntax,
        routerIdentifier: String,
        context: some MacroExpansionContext
    ) -> [String] {
        declaration.memberBlock.members.compactMap { member in
            if let expansion = member.decl.as(MacroExpansionDeclSyntax.self),
               let macroName = RouteMacroName(rawValue: expansion.macroName.text) {
                guard !hasAttribute(named: openAPIIgnoredAttributeName, in: expansion.attributes) else {
                    return nil
                }
                // Route diagnostics own malformed invocations. Do not emit secondary OpenAPI
                // warnings or descriptors until the route has a valid trailing closure.
                guard let closure = expansion.trailingClosure else { return nil }
                let spec = routeSpec(from: expansion, macroName: macroName)
                let inferredResponseType = closureReturnType(from: closure)
                    .flatMap(inferableOpenAPIResponseType)
                if inferredResponseType == nil,
                   !hasExplicitOpenAPIResponse(in: expansion.attributes) {
                    context.diagnose(
                        Diagnostic(node: Syntax(expansion), message: OpenAPIInferenceDiagnostic())
                    )
                }
                return openAPIHandlerExpression(
                    identifier: "\(routerIdentifier).\(spec.method).\(spec.path)",
                    method: spec.method,
                    path: spec.path,
                    parameters: [],
                    requestBody: explicitOpenAPIRequestBody(in: expansion.attributes),
                    inferredResponseType: inferredResponseType,
                    attributes: expansion.attributes
                )
            }

            guard let function = member.decl.as(FunctionDeclSyntax.self) else { return nil }
            guard !hasAttribute(named: openAPIIgnoredAttributeName, in: function.attributes) else {
                return nil
            }
            if let attribute = typedRouteAttribute(from: function.attributes),
               let name = attributeName(of: attribute),
               let macroName = RouteMacroName(rawValue: name) {
                let spec = routeSpec(from: attribute, macroName: macroName)
                let parameters = openAPIParameters(
                    from: function,
                    in: declaration,
                    routerIdentifier: routerIdentifier
                )
                let requestBody = openAPIRequestBody(
                    from: function,
                    in: declaration,
                    routerIdentifier: routerIdentifier,
                    context: context
                )
                let inferredResponseType = function.signature.returnClause
                    .map { $0.type.trimmedDescription }
                    .flatMap(inferableOpenAPIResponseType) ?? (function.signature.returnClause == nil ? "Void" : nil)
                diagnoseUninferableOpenAPIResponse(
                    inferredResponseType,
                    attributes: function.attributes,
                    node: Syntax(function),
                    context: context
                )
                return openAPIHandlerExpression(
                    identifier: "\(routerIdentifier).\(function.name.text)",
                    method: spec.method,
                    path: spec.path,
                    parameters: parameters,
                    requestBody: requestBody,
                    inferredResponseType: inferredResponseType,
                    attributes: function.attributes
                )
            }

            if let attribute = routeHandlerAttribute(from: function.attributes) {
                let spec = routeSpec(from: attribute)
                let inferredResponseType = function.signature.returnClause
                    .map { $0.type.trimmedDescription }
                    .flatMap(inferableOpenAPIResponseType) ?? (function.signature.returnClause == nil ? "Void" : nil)
                diagnoseUninferableOpenAPIResponse(
                    inferredResponseType,
                    attributes: function.attributes,
                    node: Syntax(function),
                    context: context
                )
                return openAPIHandlerExpression(
                    identifier: "\(routerIdentifier).\(function.name.text)",
                    method: spec.method,
                    path: spec.path,
                    parameters: [],
                    requestBody: explicitOpenAPIRequestBody(in: function.attributes),
                    inferredResponseType: inferredResponseType,
                    attributes: function.attributes
                )
            }
            return nil
        }
    }

}
