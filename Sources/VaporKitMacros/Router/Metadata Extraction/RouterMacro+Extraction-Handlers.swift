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
        var injectedParameters: [InjectedParameterMetadata] = []
        var pathParameters: [PathParameterMetadata] = []
        for parameter in remainingParameters {
            let localName = localParameterName(from: parameter)
            let generatedName = context.makeUniqueName(localName)

            if let pathAttribute = pathAttribute(from: parameter.attributes) {
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

                injectedParameters.append(
                    InjectedParameterMetadata(
                        externalName: externalParameterName(from: parameter),
                        localName: localName,
                        type: parameter.type,
                        generatedName: generatedName,
                        source: .path(name: pathName)
                    )
                )
                pathParameters.append(
                    PathParameterMetadata(
                        externalName: externalParameterName(from: parameter),
                        localName: localName,
                        pathName: pathName,
                        type: parameter.type,
                        generatedName: generatedName,
                        pathAttribute: pathAttribute
                    )
                )
                continue
            }

            if let queryAttribute = queryAttribute(from: parameter.attributes) {
                guard let keyPath = queryKeyPath(from: queryAttribute) else {
                    injectedParameters.append(
                        InjectedParameterMetadata(
                            externalName: externalParameterName(from: parameter),
                            localName: localName,
                            type: parameter.type,
                            generatedName: generatedName,
                            source: .query(keyPath: nil)
                        )
                    )
                    continue
                }

                guard let keyPath else {
                    context.diagnose(
                        Diagnostic(
                            node: Syntax(queryAttribute),
                            message: RouteMacroDiagnostic.typedRouteQueryRequiresLiteralKey
                        )
                    )
                    return nil
                }

                injectedParameters.append(
                    InjectedParameterMetadata(
                        externalName: externalParameterName(from: parameter),
                        localName: localName,
                        type: parameter.type,
                        generatedName: generatedName,
                        source: .query(keyPath: keyPath)
                    )
                )
                continue
            }

            context.diagnose(
                Diagnostic(
                    node: Syntax(parameter),
                    message: RouteMacroDiagnostic.typedRouteRequiresInjectedParameterAttribute
                )
            )
            return nil
        }

        let routeSpec = routeSpec(from: routeAttribute, macroName: macroName)
        return TypedHandlerMethodMetadata(
            path: joinedURL(routerPrefix, routeSpec.path),
            method: routeSpec.method,
            middlewares: middlewareExpressions(from: function.attributes),
            requestParameter: requestParameter,
            injectedParameters: injectedParameters,
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
