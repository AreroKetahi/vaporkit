import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension ValidatableMacro {
    // Collects declarative field constraints and normalizes them into entries that codegen can emit.
    static func validationEntries(
        from member: MemberBlockItemSyntax,
        context: some MacroExpansionContext
    ) -> [ValidationEntry] {
        guard let variable = member.decl.as(VariableDeclSyntax.self) else {
            return []
        }

        let attributes = constraintAttributes(from: variable.attributes)
        guard !attributes.isEmpty else {
            return []
        }

        guard let binding = variable.bindings.onlyElement else {
            context.diagnose(
                Diagnostic(node: Syntax(variable), message: MacroDiagnostic.constraintRequiresSingleBinding)
            )
            return []
        }

        guard binding.accessorBlock == nil else {
            context.diagnose(
                Diagnostic(node: Syntax(variable), message: MacroDiagnostic.constraintRequiresStoredProperty)
            )
            return []
        }

        guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            context.diagnose(
                Diagnostic(node: Syntax(variable), message: MacroDiagnostic.constraintRequiresStoredProperty)
            )
            return []
        }

        guard let typeAnnotation = binding.typeAnnotation else {
            context.diagnose(
                Diagnostic(node: Syntax(variable), message: MacroDiagnostic.constraintRequiresExplicitType)
            )
            return []
        }

        let propertyName = identifierPattern.identifier.text
        let propertyType = typeAnnotation.type

        return attributes.compactMap { attribute in
            validationEntry(
                from: attribute,
                propertyName: propertyName,
                propertyType: propertyType,
                context: context
            )
        }
    }

    static func validationEntry(
        from attribute: AttributeSyntax,
        propertyName: String,
        propertyType: TypeSyntax,
        context: some MacroExpansionContext
    ) -> ValidationEntry? {
        if isCustomConstraintAttribute(attribute) {
            return customValidationEntry(
                from: attribute,
                propertyName: propertyName,
                propertyType: propertyType,
                context: context
            )
        }

        let arguments = attributeArguments(from: attribute)
        guard let rule = arguments.first?.expression else {
            context.diagnose(
                Diagnostic(node: Syntax(attribute), message: MacroDiagnostic.constraintRequiresRule)
            )
            return nil
        }

        let required = arguments.first(where: { $0.label?.text == "required" })?.expression
        let message = arguments.first(where: { $0.label?.text == "message" })?.expression

        if let message, !isSupportedMessageExpression(message) {
            context.diagnose(
                Diagnostic(node: Syntax(message), message: MacroDiagnostic.constraintMessageMustBeStringLiteral)
            )
            return nil
        }

        if let unsupportedNode = firstUnsupportedRule(in: rule, propertyType: propertyType) {
            context.diagnose(
                Diagnostic(node: unsupportedNode, message: MacroDiagnostic.ruleNotSupportedForType)
            )
            return nil
        }

        return ValidationEntry(
            propertyName: propertyName,
            propertyType: propertyType,
            validatorExpression: rule,
            required: required,
            message: message,
            validatorName: context.makeUniqueName("validation")
        )
    }

    static func customValidationEntry(
        from attribute: AttributeSyntax,
        propertyName: String,
        propertyType: TypeSyntax,
        context: some MacroExpansionContext
    ) -> ValidationEntry? {
        let arguments = attributeArguments(from: attribute)
        guard let validatingArgument = arguments.first(where: { $0.label?.text == "validating" }) else {
            context.diagnose(
                Diagnostic(node: Syntax(attribute), message: MacroDiagnostic.customConstraintRequiresType)
            )
            return nil
        }

        guard let closureExpression = arguments.first(where: { $0.label?.text == "with" })?.expression,
              let closure = closureExpression.as(ClosureExprSyntax.self) else {
            context.diagnose(
                Diagnostic(node: Syntax(attribute), message: MacroDiagnostic.customConstraintRequiresClosure)
            )
            return nil
        }

        let message = arguments.first(where: { $0.label?.text == "message" })?.expression
        if let message, !isSupportedMessageExpression(message) {
            context.diagnose(
                Diagnostic(node: Syntax(message), message: MacroDiagnostic.constraintMessageMustBeStringLiteral)
            )
            return nil
        }

        guard let validatingType = validatingTypeSyntax(from: validatingArgument.expression) else {
            context.diagnose(
                Diagnostic(node: Syntax(validatingArgument.expression), message: MacroDiagnostic.customConstraintRequiresType)
            )
            return nil
        }

        let propertyValidationType = effectiveValidationType(for: propertyType)
        if normalizeTypeName(validatingType) != normalizeTypeName(propertyValidationType) {
            context.diagnose(
                Diagnostic(node: Syntax(validatingArgument.expression), message: MacroDiagnostic.customConstraintTypeMismatch)
            )
            return nil
        }

        let validatorExpression: ExprSyntax = """
        .custom(\(message ?? "\"Invalid value\""), validationClosure: { value in
            return (\(closure))(value)
        })
        """

        return ValidationEntry(
            propertyName: propertyName,
            propertyType: propertyType,
            validatorExpression: validatorExpression,
            required: isOptionalType(propertyType) ? ExprSyntax(BooleanLiteralExprSyntax(literal: .keyword(.false))) : nil,
            message: nil,
            validatorName: context.makeUniqueName("validation")
        )
    }

    static func constraintAttributes(from attributes: AttributeListSyntax) -> [AttributeSyntax] {
        attributes.compactMap { $0.as(AttributeSyntax.self) }.filter {
            attributeName(of: $0) == constraintAttributeName
        }
    }

    static func isCustomConstraintAttribute(_ attribute: AttributeSyntax) -> Bool {
        let arguments = attributeArguments(from: attribute)
        return arguments.contains { $0.label?.text == "validating" }
    }

    static func attributeArguments(from attribute: AttributeSyntax) -> LabeledExprListSyntax {
        guard case let .argumentList(arguments) = attribute.arguments else {
            return []
        }
        return arguments
    }

    static func attributeName(of attribute: AttributeSyntax) -> String? {
        if let identifierType = attribute.attributeName.as(IdentifierTypeSyntax.self) {
            return identifierType.name.text
        }

        return attribute.attributeName.as(MemberTypeSyntax.self)?.name.text
    }

    static func hasValidationsMethod(_ member: MemberBlockItemSyntax) -> Bool {
        guard let function = member.decl.as(FunctionDeclSyntax.self) else {
            return false
        }

        return function.name.text == validationsMethodName
    }
}
