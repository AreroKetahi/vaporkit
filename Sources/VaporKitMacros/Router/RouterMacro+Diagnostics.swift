import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension RouterMacro {
    static func rejectController(
        on declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext,
        diagnosing: Bool
    ) -> Bool {
        guard let controller = declaration.attributes.compactMap({
            $0.as(AttributeSyntax.self)
        }).first(where: {
            attributeName(of: $0) == controllerAttributeName
        }) else {
            return false
        }

        if diagnosing {
            diagnoseIgnoredVaporRouteMacros(in: declaration, context: context)
            context.diagnose(
                Diagnostic(
                    node: controller,
                    message: RouteMacroDiagnostic.incompatibleController,
                    fixIts: [
                        FixIt(
                            message: RouteMacroFixIt.removeController,
                            changes: [
                                .replace(
                                    oldNode: Syntax(controller),
                                    newNode: Syntax(AttributeListSyntax([]))
                                )
                            ]
                        )
                    ]
                )
            )
        }
        return true
    }

    static func diagnoseIgnoredVaporRouteMacros(
        in declaration: some DeclGroupSyntax,
        context: some MacroExpansionContext
    ) {
        let replacements = [
            "GET": "Get",
            "POST": "Post",
            "PUT": "Put",
            "DELETE": "Delete",
            "Patch": "On",
        ]

        for member in declaration.memberBlock.members {
            guard let function = member.decl.as(FunctionDeclSyntax.self) else {
                continue
            }

            for attribute in function.attributes.compactMap({ $0.as(AttributeSyntax.self) }) {
                guard let vaporName = attributeName(of: attribute),
                      let vaporKitName = replacements[vaporName]
                else {
                    continue
                }

                let fixIts = replacementForVaporRouteAttribute(
                    attribute,
                    named: vaporName,
                    replacement: vaporKitName
                ).map { replacement in
                    [
                        FixIt(
                            message: ReplaceVaporRouteMacroFixIt(
                                vaporName: vaporName,
                                vaporKitName: vaporKitName
                            ),
                            changes: [
                                .replace(oldNode: Syntax(attribute), newNode: Syntax(replacement))
                            ]
                        )
                    ]
                } ?? []

                context.diagnose(
                    Diagnostic(
                        node: attribute,
                        message: IgnoredVaporRouteMacroDiagnostic(
                            vaporName: vaporName,
                            vaporKitName: vaporKitName
                        ),
                        fixIts: fixIts
                    )
                )
            }
        }
    }

    static func replacementForVaporRouteAttribute(
        _ attribute: AttributeSyntax,
        named vaporName: String,
        replacement vaporKitName: String
    ) -> AttributeSyntax? {
        let arguments: LabeledExprListSyntax
        switch attribute.arguments {
        case .argumentList(let list):
            arguments = list
        case nil:
            arguments = []
        default:
            return nil
        }

        guard arguments.count <= 1,
              arguments.first?.label == nil
        else {
            return nil
        }

        let renderedArgument = arguments.first.map { $0.expression.trimmedDescription }
        if vaporName == "Patch" {
            let prefix = renderedArgument.map { "\($0), " } ?? ""
            return AttributeSyntax("@On(\(raw: prefix)method: .patch)")
        }

        let suffix = renderedArgument.map { "(\($0))" } ?? ""
        return AttributeSyntax("@\(raw: vaporKitName)\(raw: suffix)")
    }

    static func diagnoseMissingTrailingClosure(
        for expansion: MacroExpansionDeclSyntax,
        macroName: RouteMacroName,
        in context: some MacroExpansionContext
    ) {
        // Router declaration macros intentionally support one calling convention only:
        // `#Get("path") { ... }`. The diagnostic teaches that rule and keeps parsing simple.
        guard let actionArgument = actionArgument(in: expansion.arguments) else {
            context.diagnose(
                Diagnostic(node: expansion, message: RouteMacroDiagnostic.requiresTrailingClosure)
            )
            return
        }

        if let closureExpression = actionArgument.expression.as(ClosureExprSyntax.self),
           let fixedExpansion = fixedTrailingClosureExpansion(
               from: expansion,
               macroName: macroName,
               closureExpression: closureExpression
           )
        {
            // Closure literals can be migrated mechanically, so offer a fix-it instead of forcing
            // the user to rewrite the invocation by hand.
            context.diagnose(
                Diagnostic(
                    node: expansion,
                    message: RouteMacroDiagnostic.requiresTrailingClosure,
                    fixIts: [
                        FixIt(
                            message: RouteMacroFixIt.moveClosureToTrailing,
                            changes: [
                                .replace(oldNode: Syntax(expansion), newNode: Syntax(fixedExpansion))
                            ]
                        )
                    ]
                )
            )
            return
        }

        context.diagnose(
            Diagnostic(node: expansion, message: RouteMacroDiagnostic.doesNotAcceptClosureReference)
        )
    }

    static func actionArgument(in arguments: LabeledExprListSyntax) -> LabeledExprSyntax? {
        arguments.last { $0.label?.text == "action" }
    }

    static func fixedTrailingClosureExpansion(
        from expansion: MacroExpansionDeclSyntax,
        macroName: RouteMacroName,
        closureExpression: ClosureExprSyntax
    ) -> MacroExpansionDeclSyntax? {
        var remainingArguments = Array(expansion.arguments.dropLast())
        if let lastIndex = remainingArguments.indices.last {
            // Remove the trailing comma left behind after dropping the explicit `action:` argument.
            remainingArguments[lastIndex] = remainingArguments[lastIndex]
                .with(\.trailingComma, nil)
        }

        // Preserve everything else about the invocation and only move the closure into trailing position.
        return expansion
            .with(\.arguments, LabeledExprListSyntax(remainingArguments))
            .with(\.trailingClosure, closureExpression)
    }
}
