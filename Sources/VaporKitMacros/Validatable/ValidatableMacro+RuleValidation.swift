import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension ValidatableMacro {
    // Rule validation stays syntax-driven so the declaration DSL can remain lightweight for users.
    static func isSupportedMessageExpression(_ expression: ExprSyntax) -> Bool {
        expression.is(NilLiteralExprSyntax.self) || expression.is(StringLiteralExprSyntax.self)
    }

    static func firstUnsupportedRule(in expression: ExprSyntax, propertyType: TypeSyntax) -> Syntax? {
        let propertyKind = propertyKind(for: propertyType)
        return firstUnsupportedRule(in: Syntax(expression), propertyKind: propertyKind)
    }

    static func firstMismatchedPredicateType(in expression: ExprSyntax, propertyType: TypeSyntax) -> Syntax? {
        let expectedType = effectiveValidationType(for: propertyType)
        return firstMismatchedPredicateType(in: Syntax(expression), expectedType: expectedType)
    }

    static func firstUnsupportedRule(in syntax: Syntax, propertyKind: PropertyKind) -> Syntax? {
        if let functionCall = syntax.as(FunctionCallExprSyntax.self) {
            if let memberAccess = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
               let ruleName = ruleName(from: memberAccess) {
                return isRuleSupported(ruleName, propertyKind: propertyKind)
                    ? nil
                    : Syntax(functionCall)
            }

            return functionCall.arguments.lazy.compactMap {
                firstUnsupportedRule(in: Syntax($0.expression), propertyKind: propertyKind)
            }.first
        }

        if let memberAccess = syntax.as(MemberAccessExprSyntax.self),
           let ruleName = ruleName(from: memberAccess),
           !isRuleSupported(ruleName, propertyKind: propertyKind) {
            return Syntax(memberAccess)
        }

        if let sequence = syntax.as(SequenceExprSyntax.self) {
            return sequence.elements.lazy.compactMap {
                firstUnsupportedRule(in: Syntax($0), propertyKind: propertyKind)
            }.first
        }

        if let prefix = syntax.as(PrefixOperatorExprSyntax.self) {
            return firstUnsupportedRule(in: Syntax(prefix.expression), propertyKind: propertyKind)
        }

        if let tuple = syntax.as(TupleExprSyntax.self) {
            return tuple.elements.lazy.compactMap {
                firstUnsupportedRule(in: Syntax($0.expression), propertyKind: propertyKind)
            }.first
        }

        return nil
    }

    static func firstMismatchedPredicateType(in syntax: Syntax, expectedType: TypeSyntax) -> Syntax? {
        if let functionCall = syntax.as(FunctionCallExprSyntax.self) {
            if let memberAccess = functionCall.calledExpression.as(MemberAccessExprSyntax.self),
               ruleName(from: memberAccess) == "predicate",
               let predicateType = explicitPredicateType(from: functionCall) {
                return normalizeTypeName(predicateType) == normalizeTypeName(expectedType)
                    ? nil
                    : Syntax(predicateType)
            }

            return functionCall.arguments.lazy.compactMap {
                firstMismatchedPredicateType(in: Syntax($0.expression), expectedType: expectedType)
            }.first
        }

        if let sequence = syntax.as(SequenceExprSyntax.self) {
            return sequence.elements.lazy.compactMap {
                firstMismatchedPredicateType(in: Syntax($0), expectedType: expectedType)
            }.first
        }

        if let prefix = syntax.as(PrefixOperatorExprSyntax.self) {
            return firstMismatchedPredicateType(in: Syntax(prefix.expression), expectedType: expectedType)
        }

        if let tuple = syntax.as(TupleExprSyntax.self) {
            return tuple.elements.lazy.compactMap {
                firstMismatchedPredicateType(in: Syntax($0.expression), expectedType: expectedType)
            }.first
        }

        return nil
    }

    static func explicitPredicateType(from functionCall: FunctionCallExprSyntax) -> TypeSyntax? {
        guard let predicateExpression = functionCall.arguments.first?.expression.as(MacroExpansionExprSyntax.self),
              predicateExpression.macroName.text == "Predicate",
              let genericArgument = predicateExpression.genericArgumentClause?.arguments.onlyElement else {
            return nil
        }

        return genericArgument.argument.as(TypeSyntax.self)
    }

    static func ruleName(from memberAccess: MemberAccessExprSyntax) -> String? {
        memberAccess.declName.baseName.text
    }

    static func isRuleSupported(_ ruleName: String, propertyKind: PropertyKind) -> Bool {
        switch ruleName {
        case "ascii", "alphanumeric", "email", "url", "characterSet":
            propertyKind.baseTypeName == "String" || propertyKind.baseTypeName == "Substring"
        case "count", "empty":
            propertyKind.isCountable
        case "range":
            propertyKind.isRangeCompatible
        case "nil":
            propertyKind.isOptional
        case "in":
            true
        case "predicate":
            true
        default:
            false
        }
    }

    static func propertyKind(for type: TypeSyntax) -> PropertyKind {
        let normalizedType = normalizeTypeName(type)
        let baseType: String
        let isOptional: Bool

        if let optional = type.as(OptionalTypeSyntax.self) {
            baseType = normalizeTypeName(optional.wrappedType)
            isOptional = true
        } else if let optional = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            baseType = normalizeTypeName(optional.wrappedType)
            isOptional = true
        } else if normalizedType.hasPrefix("Optional<"), normalizedType.hasSuffix(">") {
            baseType = String(normalizedType.dropFirst("Optional<".count).dropLast())
            isOptional = true
        } else {
            baseType = normalizedType
            isOptional = false
        }

        return PropertyKind(baseTypeName: baseType, isOptional: isOptional)
    }

    static func normalizeTypeName(_ type: TypeSyntax) -> String {
        type.trimmedDescription.replacingOccurrences(of: " ", with: "")
    }

    static func validatingTypeSyntax(from expression: ExprSyntax) -> TypeSyntax? {
        let trimmed = expression.trimmedDescription
        let typeText: String
        if trimmed.hasSuffix(".self") {
            typeText = String(trimmed.dropLast(".self".count))
        } else {
            typeText = trimmed
        }

        guard !typeText.isEmpty else {
            return nil
        }

        return TypeSyntax(stringLiteral: typeText)
    }
}
