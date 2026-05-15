import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension ValidatableMacro {
    // Converts normalized entries into the `static func validations(_:)` Vapor expects today.
    static func validationsDeclaration(for entries: [ValidationEntry]) -> DeclSyntax {
        let body = entries.map(validationStatement(for:)).joined(separator: "\n")

        return """
        static func validations(_ validations: inout Vapor.Validations) {
            \(raw: body)
        }
        """
    }

    static func validationStatement(for entry: ValidationEntry) -> String {
        let validationType = effectiveValidationType(for: entry)
        let validatorName = entry.validatorName.text
        var arguments = [
            "\"\(entry.propertyName)\"",
            "as: \(validationType.trimmed).self",
            "is: \(validatorName)"
        ]

        if let required = resolvedRequiredExpression(for: entry) {
            arguments.append("required: \(required.trimmed)")
        }

        if let message = entry.message, !message.is(NilLiteralExprSyntax.self) {
            arguments.append("customFailureDescription: \(message.trimmed)")
        }

        return """
        let \(validatorName): Vapor.Validator<\(validationType.trimmed)> = \(entry.validatorExpression.trimmed)
        validations.add(\(arguments.joined(separator: ", ")))
        """
    }

    static func resolvedRequiredExpression(for entry: ValidationEntry) -> ExprSyntax? {
        if let required = entry.required {
            return required
        }

        if isOptionalType(entry.propertyType) {
            return ExprSyntax(BooleanLiteralExprSyntax(literal: .keyword(.false)))
        }

        return nil
    }

    static func effectiveValidationType(for entry: ValidationEntry) -> TypeSyntax {
        effectiveValidationType(for: entry.propertyType)
    }

    static func effectiveValidationType(for propertyType: TypeSyntax) -> TypeSyntax {
        if let optional = propertyType.as(OptionalTypeSyntax.self) {
            return optional.wrappedType
        }

        if let optional = propertyType.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return optional.wrappedType
        }

        return propertyType
    }

    static func isOptionalType(_ type: TypeSyntax) -> Bool {
        if type.is(OptionalTypeSyntax.self) || type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return true
        }

        guard let identifierType = type.as(IdentifierTypeSyntax.self),
              identifierType.name.text == "Optional",
              identifierType.genericArgumentClause != nil else {
            return false
        }

        return true
    }
}
