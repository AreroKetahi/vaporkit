import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

extension RouterMacro {
    static func handlerMethodMetadata(
        from member: MemberBlockItemSyntax,
        routerPrefix: String?,
        context: some MacroExpansionContext
    ) -> HandlerMethodMetadata? {
        // `@RouteHandler` keeps the user's function body, so extraction only needs enough
        // information to register it and validate request-bound parameter access.
        guard let function = member.decl.as(FunctionDeclSyntax.self),
            let routeHandlerAttribute = routeHandlerAttribute(
                from: function.attributes
            )
        else {
            return nil
        }

        guard isSupportedRouteHandlerSignature(function.signature) else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(function),
                    message: RouteMacroDiagnostic
                        .routeHandlerRequiresSingleRequestParameter
                )
            )
            return nil
        }

        let routeSpec = routeSpec(from: routeHandlerAttribute)
        return HandlerMethodMetadata(
            path: joinedURL(routerPrefix, routeSpec.path),
            method: routeSpec.method,
            middlewares: middlewareExpressions(from: function.attributes),
            requestKeyword: routeHandlerRequestKeyword(from: function.signature)
                ?? "req",
            parameterCheckOverride: staticCheckOverride(
                named: disableParameterCheckAttributeName,
                in: function.attributes
            ),
            body: function.body,
            functionName: function.name
        )
    }

    static func typedHandlerMethodMetadata(
        from member: MemberBlockItemSyntax,
        routerPrefix: String?,
        context: some MacroExpansionContext
    ) -> TypedHandlerMethodMetadata? {
        guard let function = member.decl.as(FunctionDeclSyntax.self),
              let routeAttribute = typedRouteAttribute(from: function.attributes),
              let macroNameText = attributeName(of: routeAttribute),
              let macroName = RouteMacroName(rawValue: macroNameText)
        else {
            return nil
        }

        guard let requestParameter = typedRouteRequestParameter(from: function.signature) else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(function),
                    message: RouteMacroDiagnostic.typedRouteRequiresRequestParameter
                )
            )
            return nil
        }

        let remainingParameters = Array(function.signature.parameterClause.parameters.dropFirst())
        var pathParameters: [PathParameterMetadata] = []
        for parameter in remainingParameters {
            guard let pathAttribute = pathAttribute(from: parameter.attributes) else {
                context.diagnose(
                    Diagnostic(
                        node: Syntax(parameter),
                        message: RouteMacroDiagnostic.typedRouteRequiresPathParameterAttribute
                    )
                )
                return nil
            }

            let localName = localParameterName(from: parameter)
            guard let pathName = pathParameterName(
                from: pathAttribute,
                defaultName: localName
            ) else {
                context.diagnose(
                    Diagnostic(
                        node: Syntax(pathAttribute),
                        message: RouteMacroDiagnostic.typedRoutePathRequiresLiteralName
                    )
                )
                return nil
            }

            pathParameters.append(
                PathParameterMetadata(
                    externalName: externalParameterName(from: parameter),
                    localName: localName,
                    pathName: pathName,
                    type: parameter.type,
                    generatedName: context.makeUniqueName(localName),
                    pathAttribute: pathAttribute
                )
            )
        }

        let routeSpec = routeSpec(from: routeAttribute, macroName: macroName)
        return TypedHandlerMethodMetadata(
            path: joinedURL(routerPrefix, routeSpec.path),
            method: routeSpec.method,
            middlewares: middlewareExpressions(from: function.attributes),
            requestParameter: requestParameter,
            pathParameters: pathParameters,
            parameterCheckOverride: staticCheckOverride(
                named: disableParameterCheckAttributeName,
                in: function.attributes
            ),
            functionName: function.name,
            wrapperName: context.makeUniqueName(function.name.text),
            explicitReturnType: function.signature.returnClause?.type.trimmedDescription,
            isAsync: function.signature.effectSpecifiers?.asyncSpecifier != nil,
            isThrowing: function.signature.effectSpecifiers?.throwsClause != nil
        )
    }
}
