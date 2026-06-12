import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension RouterMacro {
    /// Reads the router-level prefix once so every member can reuse the normalized base path.
    static func routerPrefix(from node: AttributeSyntax) -> String? {
        guard case .argumentList(let arguments) = node.arguments,
            let firstArgument = arguments.first
        else {
            return nil
        }

        return stringLiteralValue(from: firstArgument.expression)
    }

    static func functionMetadata(
        from member: MemberBlockItemSyntax,
        routerPrefix: String?,
        context: some MacroExpansionContext
    ) -> FunctionMetadata? {
        // Freestanding declarations are only considered route declarations when the macro name
        // matches one of the supported HTTP helpers.
        guard let expansion = member.decl.as(MacroExpansionDeclSyntax.self),
            let macroName = RouteMacroName(rawValue: expansion.macroName.text)
        else {
            return nil
        }

        guard let closure = expansion.trailingClosure else {
            diagnoseMissingTrailingClosure(
                for: expansion,
                macroName: macroName,
                in: context
            )
            return nil
        }

        let routeSpec = routeSpec(from: expansion, macroName: macroName)
        let requestKeyword = closureRequestKeyword(from: closure)

        // The original closure body is preserved verbatim and only rewritten later if `$0` was used.
        return FunctionMetadata(
            path: joinedURL(routerPrefix, routeSpec.path),
            method: routeSpec.method,
            middlewares: middlewareExpressions(from: expansion.attributes),
            requestKeyword: requestKeyword,
            explicitReturnType: closureReturnType(from: closure),
            parameterCheckOverride: staticCheckOverride(
                named: disableParameterCheckAttributeName,
                in: expansion.attributes
            ),
            generatedRequestKeyword: context.makeUniqueName("request"),
            content: closure.statements,
            innerName: context.makeUniqueName(generatedHandlerName)
        )
    }

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

            guard let pathName = pathParameterName(from: pathAttribute) else {
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
                    localName: localParameterName(from: parameter),
                    pathName: pathName,
                    type: parameter.type,
                    generatedName: context.makeUniqueName(localParameterName(from: parameter)),
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

    static func registeredRouterMetadata(
        from member: MemberBlockItemSyntax,
        routerPrefix: String?
    ) -> RegisteredRouterMetadata? {
        guard let expansion = member.decl.as(MacroExpansionDeclSyntax.self),
            expansion.macroName.text == registerMacroName
        else {
            return nil
        }

        return RegisteredRouterMetadata(
            routers: expansion.arguments.map(\.expression),
            routerPrefix: routerPrefix
        )
    }

    static func forwardedParameters(
        from members: MemberBlockItemListSyntax
    ) -> Set<String> {
        var parameters: Set<String> = []

        for member in members {
            guard let expansion = member.decl.as(MacroExpansionDeclSyntax.self),
                expansion.macroName.text == forwardParametersMacroName
            else {
                continue
            }

            for argument in expansion.arguments {
                if let parameter = stringLiteralValue(from: argument.expression) {
                    parameters.insert(parameter)
                }
            }
        }

        return parameters
    }

    static func webSocketMetadata(
        from member: MemberBlockItemSyntax,
        routerPrefix: String?,
        context: some MacroExpansionContext
    ) -> WebSocketMetadata? {
        guard let expansion = member.decl.as(MacroExpansionDeclSyntax.self),
            expansion.macroName.text == webSocketMacroName
        else {
            return nil
        }

        guard let closure = expansion.trailingClosure else {
            context.diagnose(
                Diagnostic(
                    node: expansion,
                    message: RouteMacroDiagnostic
                        .webSocketRequiresTrailingClosure
                )
            )
            return nil
        }

        let didUpgradeClosure: ClosureExprSyntax
        let shouldUpgradeExpression: ExprSyntax?
        if let additionalClosure = webSocketDidUpgradeClosure(
            from: expansion,
            context: context
        ) {
            didUpgradeClosure = additionalClosure
            shouldUpgradeExpression = ExprSyntax(closure)
        } else {
            didUpgradeClosure = closure
            shouldUpgradeExpression =
                expansion.arguments.first(where: {
                    $0.label?.text == "shouldUpgrade"
                })?.expression
        }

        let events = didUpgradeClosure.statements.compactMap {
            webSocketEventMetadata(from: $0, context: context)
        }

        let shouldUpgrade = shouldUpgradeMetadata(
            from: shouldUpgradeExpression,
            context: context
        )

        return WebSocketMetadata(
            path: joinedURL(
                routerPrefix,
                routeHandlerPath(from: expansion.arguments)
            ),
            middlewares: middlewareExpressions(from: expansion.attributes),
            maxFrameSize: expansion.arguments.first(where: {
                $0.label?.text == "maxFrameSize"
            })?.expression,
            shouldUpgrade: shouldUpgrade,
            events: events,
            innerName: context.makeUniqueName("WebSocketHandler"),
            shouldUpgradeName: shouldUpgrade == nil
                ? nil : context.makeUniqueName("WebSocketShouldUpgrade")
        )
    }

    static func webSocketDidUpgradeClosure(
        from expansion: MacroExpansionDeclSyntax,
        context: some MacroExpansionContext
    ) -> ClosureExprSyntax? {
        guard !expansion.additionalTrailingClosures.isEmpty else {
            return nil
        }

        guard expansion.additionalTrailingClosures.count == 1,
            let additional = expansion.additionalTrailingClosures.first,
            additional.label.text == webSocketDidUpgradeLabel
        else {
            for additional in expansion.additionalTrailingClosures {
                context.diagnose(
                    Diagnostic(
                        node: additional,
                        message: RouteMacroDiagnostic
                            .webSocketInvalidAdditionalClosureLabel
                    )
                )
            }
            return nil
        }

        return additional.closure
    }

    static func shouldUpgradeMetadata(
        from expression: ExprSyntax?,
        context: some MacroExpansionContext
    ) -> ShouldUpgradeMetadata? {
        guard let expression else {
            return nil
        }

        guard let closure = expression.as(ClosureExprSyntax.self) else {
            return ShouldUpgradeMetadata(
                expression: expression,
                requestKeyword: nil,
                body: nil,
                generatedRequestKeyword: context.makeUniqueName("request")
            )
        }

        let requestKeyword = closureRequestKeyword(from: closure)
        return ShouldUpgradeMetadata(
            expression: expression,
            requestKeyword: requestKeyword,
            body: closure.statements,
            generatedRequestKeyword: context.makeUniqueName("request")
        )
    }

    static func webSocketEventMetadata(
        from statement: CodeBlockItemSyntax,
        context: some MacroExpansionContext
    ) -> WebSocketEventMetadata? {
        guard let expansion = statement.item.as(MacroExpansionExprSyntax.self),
            let macroName = WebSocketEventMacroName(
                rawValue: expansion.macroName.text
            )
        else {
            context.diagnose(
                Diagnostic(
                    node: statement,
                    message: RouteMacroDiagnostic
                        .webSocketOnlySupportsEventMacros
                )
            )
            return nil
        }

        guard let closure = expansion.trailingClosure else {
            context.diagnose(
                Diagnostic(
                    node: expansion,
                    message: RouteMacroDiagnostic
                        .webSocketEventRequiresTrailingClosure
                )
            )
            return nil
        }

        let parameterCount = closureParameterCount(in: closure)
        switch macroName {
        case .onText, .onBinary:
            guard parameterCount == 0 || parameterCount == 2 else {
                context.diagnose(
                    Diagnostic(
                        node: expansion,
                        message: RouteMacroDiagnostic
                            .webSocketEventInvalidSignature
                    )
                )
                return nil
            }
        case .onClose:
            guard parameterCount == 0 else {
                context.diagnose(
                    Diagnostic(
                        node: expansion,
                        message: RouteMacroDiagnostic
                            .webSocketCloseInvalidSignature
                    )
                )
                return nil
            }
        }

        let shorthandBody: CodeBlockItemListSyntax?
        let generatedWebSocketKeyword: TokenSyntax?
        let generatedPayloadKeyword: TokenSyntax?
        if parameterCount == 0, macroName == .onText || macroName == .onBinary {
            let webSocketKeyword = context.makeUniqueName("webSocket")
            let payloadKeyword = context.makeUniqueName(
                macroName == .onText ? "text" : "buffer"
            )
            let rewriter = WebSocketEventShorthandRewriter(
                webSocketIdentifier: webSocketKeyword.text,
                payloadIdentifier: payloadKeyword.text
            )
            shorthandBody = rewriter.rewrite(Syntax(closure.statements))
                .cast(CodeBlockItemListSyntax.self)
            generatedWebSocketKeyword = webSocketKeyword
            generatedPayloadKeyword = payloadKeyword
        } else {
            shorthandBody = nil
            generatedWebSocketKeyword = nil
            generatedPayloadKeyword = nil
        }

        return WebSocketEventMetadata(
            kind: macroName,
            closure: closure,
            shorthandBody: shorthandBody,
            generatedWebSocketKeyword: generatedWebSocketKeyword,
            generatedPayloadKeyword: generatedPayloadKeyword
        )
    }

    static func routeHandlerAttribute(from attributes: AttributeListSyntax)
        -> AttributeSyntax?
    {
        attributes.compactMap { element in
            element.as(AttributeSyntax.self)
        }.first { attribute in
            attributeName(of: attribute) == routeHandlerAttributeName
        }
    }

    static func typedRouteAttribute(from attributes: AttributeListSyntax)
        -> AttributeSyntax?
    {
        attributes.compactMap { element in
            element.as(AttributeSyntax.self)
        }.first { attribute in
            guard let name = attributeName(of: attribute) else {
                return false
            }

            return RouteMacroName(rawValue: name) != nil
        }
    }

    static func pathAttribute(from attributes: AttributeListSyntax)
        -> AttributeSyntax?
    {
        attributes.compactMap { element in
            element.as(AttributeSyntax.self)
        }.first { attribute in
            attributeName(of: attribute) == typedPathAttributeName
        }
    }

    static func pathParameterName(from attribute: AttributeSyntax) -> String? {
        guard case .argumentList(let arguments) = attribute.arguments,
              let firstArgument = arguments.first(where: { $0.label == nil })
        else {
            return nil
        }

        return stringLiteralValue(from: firstArgument.expression)
    }

    static func middlewareExpressions(from attributes: AttributeListSyntax)
        -> [ExprSyntax]
    {
        var expressions: [ExprSyntax] = []

        for element in attributes {
            guard let attribute = element.as(AttributeSyntax.self),
                attributeName(of: attribute) == middlewareAttributeName,
                case .argumentList(let arguments) = attribute.arguments
            else {
                continue
            }

            expressions.append(contentsOf: arguments.map(\.expression))
        }

        return expressions
    }

    static func hasAttribute(
        named expectedName: String,
        in attributes: AttributeListSyntax
    ) -> Bool {
        attributes.contains { element in
            guard let attribute = element.as(AttributeSyntax.self) else {
                return false
            }

            return attributeName(of: attribute) == expectedName
        }
    }

    static func staticCheckOverride(
        named expectedName: String,
        in attributes: AttributeListSyntax
    ) -> StaticCheckOverride? {
        attributes.lazy.compactMap { element -> AttributeSyntax? in
            guard let attribute = element.as(AttributeSyntax.self),
                  attributeName(of: attribute) == expectedName else {
                return nil
            }

            return attribute
        }.compactMap(staticCheckOverride(from:)).first
    }

    static func staticCheckOverride(from attribute: AttributeSyntax) -> StaticCheckOverride {
        guard case .argumentList(let arguments) = attribute.arguments else {
            return .error
        }

        return staticCheckOverride(from: arguments) ?? .error
    }

    static func staticCheckOverride(from macro: MacroExpansionExprSyntax) -> StaticCheckOverride {
        staticCheckOverride(from: macro.arguments) ?? .error
    }

    static func staticCheckOverride(from arguments: LabeledExprListSyntax) -> StaticCheckOverride? {
        guard let severity = arguments.first(where: { $0.label?.text == "as" })?.expression else {
            return nil
        }

        let description = severity.trimmedDescription
        if description == ".warning" || description == "StaticCheckSeverity.warning" {
            return .warning
        }
        if description == ".error" || description == "StaticCheckSeverity.error" {
            return .error
        }

        return nil
    }

    static func attributeName(of attribute: AttributeSyntax) -> String? {
        // Attributes can surface as either plain identifiers or member types depending on syntax.
        if let identifierType = attribute.attributeName.as(
            IdentifierTypeSyntax.self
        ) {
            return identifierType.name.text
        }

        return attribute.attributeName.as(MemberTypeSyntax.self)?.name.text
    }

    static func routeHandlerRequestKeyword(
        from signature: FunctionSignatureSyntax
    ) -> String? {
        let parameters = signature.parameterClause.parameters
        guard let firstParameter = parameters.first else {
            return nil
        }

        // For declarations like `_ req: Request`, use the second name because it is the local one.
        if let secondName = firstParameter.secondName {
            return secondName.text
        }

        return firstParameter.firstName.text
    }

    static func typedRouteRequestParameter(
        from signature: FunctionSignatureSyntax
    ) -> FunctionParameterMetadata? {
        guard let firstParameter = signature.parameterClause.parameters.first,
              isRequestParameter(firstParameter)
        else {
            return nil
        }

        return FunctionParameterMetadata(
            externalName: externalParameterName(from: firstParameter),
            localName: localParameterName(from: firstParameter)
        )
    }

    static func isRequestParameter(_ parameter: FunctionParameterSyntax) -> Bool {
        let typeName = parameter.type.trimmedDescription.filter {
            !$0.isWhitespace
        }
        return typeName == "Request" || typeName == "Vapor.Request"
    }

    static func externalParameterName(from parameter: FunctionParameterSyntax) -> String? {
        let firstName = parameter.firstName.text
        return firstName == "_" ? nil : firstName
    }

    static func localParameterName(from parameter: FunctionParameterSyntax) -> String {
        parameter.secondName?.text ?? parameter.firstName.text
    }

    static func isSupportedRouteHandlerSignature(
        _ signature: FunctionSignatureSyntax
    ) -> Bool {
        let parameters = signature.parameterClause.parameters
        guard parameters.count == 1,
            let firstParameter = parameters.first
        else {
            return false
        }

        // Validation intentionally stays syntax-based: a single Request/Vapor.Request parameter is
        // the minimum contract needed for registration and body analysis.
        let typeName = firstParameter.type.trimmedDescription.filter {
            !$0.isWhitespace
        }
        return typeName == "Request" || typeName == "Vapor.Request"
    }

    static func closureParameterCount(in closure: ClosureExprSyntax) -> Int {
        guard let parameterClause = closure.signature?.parameterClause else {
            return 0
        }

        if let shorthand = parameterClause.as(
            ClosureShorthandParameterListSyntax.self
        ) {
            return shorthand.count
        }

        if let explicit = parameterClause.as(ClosureParameterClauseSyntax.self)
        {
            return explicit.parameters.count
        }

        return 0
    }

    static func closureRequestKeyword(from closure: ClosureExprSyntax)
        -> String?
    {
        guard let parameterClause = closure.signature?.parameterClause else {
            return nil
        }

        if let shorthand = parameterClause.as(
            ClosureShorthandParameterListSyntax.self
        ) {
            return shorthand.first?.name.text
        }

        if let explicit = parameterClause.as(ClosureParameterClauseSyntax.self)
        {
            guard let firstParameter = explicit.parameters.first else {
                return nil
            }

            return (firstParameter.secondName ?? firstParameter.firstName).text
        }

        return nil
    }

    static func closureReturnType(from closure: ClosureExprSyntax) -> String? {
        closure.signature?.returnClause?.type.trimmedDescription
    }
}
