import SwiftSyntax

extension RouterMacro {
    /// Reads the router-level prefix once so every member can reuse the normalized base path.
    static func routerPrefix(from node: AttributeSyntax) -> String? {
        routerPath(from: node)?.path
    }

    static func routerPath(
        from node: AttributeSyntax
    ) -> ParsedRouterPath? {
        guard case .argumentList(let arguments) = node.arguments,
            let firstArgument = arguments.first
        else {
            return nil
        }

        let parsed = parsedRouterPath(from: firstArgument.expression)
        guard let literal = firstArgument.expression.as(StringLiteralExprSyntax.self),
              let firstSegment = literal.segments.first?.as(StringSegmentSyntax.self),
              firstSegment.content.text.hasPrefix("/"),
              !parsed.path.isEmpty
        else {
            return parsed
        }

        return .init(
            path: "/\(parsed.path)",
            parameterStrategies: parsed.parameterStrategies,
            diagnostics: parsed.diagnostics
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
}
