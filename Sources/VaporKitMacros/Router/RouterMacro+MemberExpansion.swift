import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension RouterMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Member expansion is the high-level orchestration point:
        // 1. parse both route declaration styles into metadata
        // 2. validate route contracts against handler bodies
        // 3. generate boot registration + synthesized wrapper handlers
        let routerPrefix = routerPrefix(from: node)
        let routerDisablesParameterCheck = hasAttribute(
            named: disableParameterCheckAttributeName,
            in: declaration.attributes
        )
        let forwardedParameters = forwardedParameters(from: declaration.memberBlock.members)
        let declarationFunctions = declaration.memberBlock.members.compactMap {
            functionMetadata(from: $0, routerPrefix: routerPrefix, context: context)
        }
        let handlerMethods = declaration.memberBlock.members.compactMap {
            handlerMethodMetadata(from: $0, routerPrefix: routerPrefix, context: context)
        }
        let registeredRouters = declaration.memberBlock.members.compactMap {
            registeredRouterMetadata(from: $0, routerPrefix: routerPrefix)
        }
        let webSockets = declaration.memberBlock.members.compactMap {
            webSocketMetadata(from: $0, routerPrefix: routerPrefix, context: context)
        }

        if !routerDisablesParameterCheck {
            validateRequiredParameters(
                in: declarationFunctions,
                forwardedParameters: forwardedParameters,
                context: context
            )
            validateRequiredParameters(
                in: handlerMethods,
                forwardedParameters: forwardedParameters,
                context: context
            )
        }

        // Existing `@RouteHandler` functions already exist in source, so only freestanding
        // declarations need synthesized wrapper methods.
        var result: [DeclSyntax] = [
            bootDeclaration(
                for: declarationFunctions,
                handlerMethods: handlerMethods,
                registeredRouters: registeredRouters,
                webSockets: webSockets
            )
        ]
        result.append(contentsOf: declarationFunctions.map(handlerDeclaration(for:)))
        result.append(contentsOf: webSockets.compactMap(shouldUpgradeDeclaration(for:)))
        result.append(contentsOf: webSockets.map(handlerDeclaration(for:)))
        return result
    }
}
