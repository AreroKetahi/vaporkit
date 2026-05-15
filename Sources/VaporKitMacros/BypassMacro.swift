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
        case requiresSingleExpression = "#Bypass only supports a single expression in its closure body."

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

        guard closure.statements.count == 1,
              let onlyStatement = closure.statements.first,
              let expression = onlyStatement.item.as(ExprSyntax.self)
        else {
            context.diagnose(
                Diagnostic(node: Syntax(node), message: BypassDiagnostic.requiresSingleExpression)
            )
            return "()"
        }

        // `#Bypass` is intentionally a pure identity macro. Its only job is to leave a syntax
        // marker for analyzers and then erase itself during expansion.
        return expression
    }
}
