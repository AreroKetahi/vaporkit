import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension RouterMacro {
    static func bootDeclaration(
        for functions: [FunctionMetadata],
        handlerMethods: [HandlerMethodMetadata],
        typedHandlerMethods: [TypedHandlerMethodMetadata],
        registeredRouters: [RegisteredRouterMetadata],
        webSockets: [WebSocketMetadata]
    ) -> DeclSyntax {
        // Freestanding declarations register first, then existing `@RouteHandler` methods append
        // after them so both routing styles can coexist deterministically.
        let registrations = (
            functions.map(routeRegistration(for:)) +
            handlerMethods.map(routeRegistration(for:)) +
            typedHandlerMethods.map(routeRegistration(for:)) +
            registeredRouters.flatMap(routeRegistrations(for:)) +
            webSockets.map(routeRegistration(for:))
        ).joined(separator: "\n")

        return """
        func boot(routes: any Vapor.RoutesBuilder) throws {
            \(raw: registrations)
        }
        """
    }

    static func routeRegistration(for metadata: FunctionMetadata) -> String {
        let path = splitURL(metadata.path)
        let builder = routeBuilderExpression(from: metadata.middlewares)
        guard !path.isEmpty else {
            return "\(builder).on(.\(metadata.method), use: \(metadata.innerName))"
        }

        return "\(builder).on(.\(metadata.method), \(path), use: \(metadata.innerName))"
    }

    static func routeRegistration(for metadata: HandlerMethodMetadata) -> String {
        let path = splitURL(metadata.path)
        let builder = routeBuilderExpression(from: metadata.middlewares)
        guard !path.isEmpty else {
            return "\(builder).on(.\(metadata.method), use: \(metadata.functionName))"
        }

        return "\(builder).on(.\(metadata.method), \(path), use: \(metadata.functionName))"
    }

    static func routeRegistration(for metadata: TypedHandlerMethodMetadata) -> String {
        let path = splitURL(metadata.path)
        let builder = routeBuilderExpression(from: metadata.middlewares)
        guard !path.isEmpty else {
            return "\(builder).on(.\(metadata.method), use: \(metadata.wrapperName))"
        }

        return "\(builder).on(.\(metadata.method), \(path), use: \(metadata.wrapperName))"
    }

    static func routeRegistration(for metadata: WebSocketMetadata) -> String {
        let builder = routeBuilderExpression(from: metadata.middlewares)
        let renderedPath = splitURL(metadata.path)
        var arguments: [String] = []

        if !renderedPath.isEmpty {
            arguments.append(renderedPath)
        }

        if let maxFrameSize = metadata.maxFrameSize {
            arguments.append("maxFrameSize: \(maxFrameSize.trimmedDescription)")
        }

        if let shouldUpgradeName = metadata.shouldUpgradeName {
            arguments.append("shouldUpgrade: \(shouldUpgradeName)")
        }

        arguments.append("onUpgrade: \(metadata.innerName)")
        return "\(builder).webSocket(\(arguments.joined(separator: ", ")))"
    }

    static func routeRegistrations(for metadata: RegisteredRouterMetadata) -> [String] {
        let builder: String
        let path = splitURL(metadata.routerPrefix ?? "")
        if path.isEmpty {
            builder = "routes"
        } else {
            builder = "routes.grouped(\(path))"
        }

        return metadata.routers.map {
            "try \(builder).register(collection: \($0.trimmedDescription))"
        }
    }

    static func routeBuilderExpression(from middlewares: [ExprSyntax]) -> String {
        guard !middlewares.isEmpty else {
            return "routes"
        }

        let renderedMiddlewares = middlewares.map(\.trimmedDescription).joined(separator: ", ")
        return "routes.grouped(\(renderedMiddlewares))"
    }

    static func splitURL(_ url: String) -> String {
        pathSegments(from: url)
            .map { #""\#($0)""# }
            .joined(separator: ", ")
    }

    static func handlerDeclaration(for metadata: FunctionMetadata) -> DeclSyntax {
        // The generated wrapper is the boundary where the Router DSL becomes regular Vapor code.
        """
        func \(metadata.innerName)(\(raw: metadata.resolvedRequestKeyword): Vapor.Request) async throws -> \(raw: metadata.responseType) {\(metadata.resolvedContent)}
        """
    }

    static func handlerDeclaration(for metadata: TypedHandlerMethodMetadata) -> DeclSyntax {
        let requestParameter = renderedParameter(metadata.requestParameter)
        let requestLocalName = metadata.requestParameter.localName
        let extractions = metadata.injectedParameters.map { parameter in
            injectedParameterExtraction(parameter, requestLocalName: requestLocalName)
        }.joined(separator: "\n")
        let arguments = (
            [renderedArgument(metadata.requestParameter, value: requestLocalName)] +
            metadata.injectedParameters.map { parameter in
                renderedArgument(parameter, value: parameter.generatedName.text)
            }
        ).joined(separator: ", ")
        let callPrefix = "\(metadata.isThrowing ? "try " : "")\(metadata.isAsync ? "await " : "")"

        return """
        func \(metadata.wrapperName)(\(raw: requestParameter): Vapor.Request) async throws -> \(raw: metadata.responseType) {
            \(raw: extractions)
            return \(raw: callPrefix)\(metadata.functionName)(\(raw: arguments))
        }
        """
    }

    static func injectedParameterExtraction(
        _ parameter: InjectedParameterMetadata,
        requestLocalName: String
    ) -> String {
        let tryKeyword = renderedDecodingTry(for: parameter)
        let type = renderedDecodingType(for: parameter)

        switch parameter.source {
        case .path(let name):
            return """
            let \(parameter.generatedName) = try \(requestLocalName).parameters.require("\(name)", as: \(parameter.type.trimmedDescription).self)
            """
        case .query(nil):
            return """
            let \(parameter.generatedName) = \(tryKeyword) \(requestLocalName).query.decode(\(type).self)
            """
        case .query(.some(let keyPath)):
            let renderedPath = keyPath.map { #""\#($0)""# }.joined(separator: ", ")
            return """
            let \(parameter.generatedName) = \(tryKeyword) \(requestLocalName).query.get(\(type).self, at: \(renderedPath))
            """
        case .content:
            return """
            let \(parameter.generatedName) = \(tryKeyword) \(requestLocalName).content.decode(\(type).self)
            """
        case .auth:
            if parameter.defaultValue != nil || isOptionalType(parameter.type) {
                return """
                let \(parameter.generatedName) = \(requestLocalName).auth.get(\(type).self)
                """
            }

            return """
            let \(parameter.generatedName) = try \(requestLocalName).auth.require(\(parameter.type.trimmedDescription).self)
            """
        }
    }

    static func renderedDecodingTry(for parameter: InjectedParameterMetadata) -> String {
        if parameter.defaultValue != nil || isOptionalType(parameter.type) {
            return "try?"
        }

        return "try"
    }

    static func renderedDecodingType(for parameter: InjectedParameterMetadata) -> String {
        if parameter.defaultValue != nil {
            return parameter.type.trimmedDescription
        }

        return optionalWrappedTypeDescription(of: parameter.type) ?? parameter.type.trimmedDescription
    }

    static func optionalWrappedTypeDescription(of type: TypeSyntax) -> String? {
        if let optional = type.as(OptionalTypeSyntax.self) {
            return optional.wrappedType.trimmedDescription
        }

        if let optional = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return optional.wrappedType.trimmedDescription
        }

        return nil
    }

    static func isOptionalType(_ type: TypeSyntax) -> Bool {
        optionalWrappedTypeDescription(of: type) != nil
    }

    static func handlerDeclaration(for metadata: WebSocketMetadata) -> DeclSyntax {
        let eventRegistrations = metadata.events.map(webSocketEventRegistration(for:)).joined(separator: "\n")
        return """
        func \(metadata.innerName)(req: Vapor.Request, ws: Vapor.WebSocket) async {
            let _ = req
            \(raw: eventRegistrations)
        }
        """
    }

    static func shouldUpgradeDeclaration(for metadata: WebSocketMetadata) -> DeclSyntax? {
        guard let shouldUpgrade = metadata.shouldUpgrade,
              let shouldUpgradeName = metadata.shouldUpgradeName else {
            return nil
        }

        if let body = shouldUpgrade.body {
            let resolvedBody: CodeBlockItemListSyntax
            if shouldUpgrade.requestKeyword == nil {
                let rewriter = ShorthandRequestRewriter(replacementIdentifier: shouldUpgrade.resolvedRequestKeyword)
                resolvedBody = rewriter.rewrite(Syntax(body)).cast(CodeBlockItemListSyntax.self)
            } else {
                resolvedBody = body
            }

            return """
            func \(shouldUpgradeName)(\(raw: shouldUpgrade.resolvedRequestKeyword): Vapor.Request) async throws -> Vapor.HTTPHeaders? {\(resolvedBody)}
            """
        }

        return """
        func \(shouldUpgradeName)(\(raw: shouldUpgrade.resolvedRequestKeyword): Vapor.Request) async throws -> Vapor.HTTPHeaders? {
            \(raw: shouldUpgrade.expression.trimmedDescription)(\(raw: shouldUpgrade.resolvedRequestKeyword))
        }
        """
    }

    static func webSocketEventRegistration(for metadata: WebSocketEventMetadata) -> String {
        switch metadata.kind {
        case .onText, .onBinary:
            if let shorthandBody = metadata.shorthandBody,
               let webSocketKeyword = metadata.generatedWebSocketKeyword,
               let payloadKeyword = metadata.generatedPayloadKeyword {
                return """
                \(metadata.kind.callbackExpression) { \(webSocketKeyword), \(payloadKeyword) in
                    \(shorthandBody.trimmedDescription)
                }
                """
            }

            return "\(metadata.kind.callbackExpression) \(normalizedClosureExpression(metadata.closure))"
        case .onClose:
            let content = metadata.closure.statements.trimmedDescription
            return """
            ws.onClose.whenComplete { _ in
                \(content)
            }
            """
        }
    }

    static func normalizedClosureExpression(_ closure: ClosureExprSyntax) -> String {
        let lines = closure.trimmedDescription.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard lines.count > 1 else {
            return closure.trimmedDescription
        }

        let firstLine = lines[0].trimmingCharacters(in: .whitespaces)
        let bodyLines = lines.dropFirst().dropLast().map {
            "    " + $0.trimmingCharacters(in: .whitespaces)
        }
        let lastLine = lines.last?.trimmingCharacters(in: .whitespaces) ?? "}"
        return ([firstLine] + bodyLines + [lastLine]).joined(separator: "\n")
    }

    static func renderedParameter(_ parameter: FunctionParameterMetadata) -> String {
        guard let externalName = parameter.externalName else {
            return "_ \(parameter.localName)"
        }

        if externalName == parameter.localName {
            return parameter.localName
        }

        return "\(externalName) \(parameter.localName)"
    }

    static func renderedArgument(_ parameter: FunctionParameterMetadata, value: String) -> String {
        guard let externalName = parameter.externalName else {
            return value
        }

        return "\(externalName): \(value)"
    }

    static func renderedArgument(_ parameter: InjectedParameterMetadata, value: String) -> String {
        let renderedValue: String
        if let defaultValue = parameter.defaultValue,
           !isPathParameter(parameter)
        {
            renderedValue = "\(value) ?? \(defaultValue.trimmedDescription)"
        } else {
            renderedValue = value
        }

        guard let externalName = parameter.externalName else {
            return renderedValue
        }

        return "\(externalName): \(renderedValue)"
    }

    static func isPathParameter(_ parameter: InjectedParameterMetadata) -> Bool {
        if case .path = parameter.source {
            return true
        }

        return false
    }

    static func nominalTypeName(of declaration: some DeclGroupSyntax) -> String? {
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            return structDecl.name.text
        }
        if let classDecl = declaration.as(ClassDeclSyntax.self) {
            return classDecl.name.text
        }
        if let actorDecl = declaration.as(ActorDeclSyntax.self) {
            return actorDecl.name.text
        }
        return nil
    }
}
