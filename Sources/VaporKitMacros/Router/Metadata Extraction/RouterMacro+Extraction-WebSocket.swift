import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

extension RouterMacro {
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
}
