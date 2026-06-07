import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct BypassMacro {}

extension BypassMacro {
    enum DiagnosticDomain {
        static let domain = "VaporKit.BypassMacro"
    }

    enum BypassDiagnostic: String, DiagnosticMessage {
        case requiresTrailingClosure = "#Bypass requires a trailing closure."

        var message: String { rawValue }
        var diagnosticID: MessageID { .init(domain: DiagnosticDomain.domain, id: "\(self)") }
        var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
    }
}

extension BypassMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        let closure = node.trailingClosure ?? node.arguments
            .first(where: { $0.label == nil })?
            .expression
            .as(ClosureExprSyntax.self)

        guard let closure else {
            context.diagnose(
                Diagnostic(node: Syntax(node), message: BypassDiagnostic.requiresTrailingClosure)
            )
            return "()"
        }

        if closure.statements.count == 1,
           let onlyStatement = closure.statements.first,
           let expression = onlyStatement.item.as(ExprSyntax.self)
        {
            // Preserve the historical identity expansion for single-expression bypasses.
            return expression
        }

        // Multi-statement bypasses preserve the original closure boundary by immediately
        // invoking the supplied closure after the syntax-only marker has been erased.
        return ExprSyntax("\(closure)()")
    }
}
