import SwiftSyntax
import SwiftSyntaxMacros

extension RouterMacro {
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
}
