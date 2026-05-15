import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension RouterMacro {
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
