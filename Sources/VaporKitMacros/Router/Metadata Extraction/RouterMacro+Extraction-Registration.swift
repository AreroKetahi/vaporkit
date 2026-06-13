import SwiftSyntax

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
