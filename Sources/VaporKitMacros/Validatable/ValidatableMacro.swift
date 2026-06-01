import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ValidatableMacro {
    static let modelAttributeName = "ValidatableModel"
    static let constraintAttributeName = "Constraint"
    static let validationsMethodName = "validations"

    enum DiagnosticDomain {
        static let domain = "VaporKit.ValidatableMacro"
    }

    enum MacroDiagnostic: String, DiagnosticMessage {
        case requiresStructOrClass = "@ValidatableModel can only be attached to a struct or class."
        case duplicateValidationsMethod = "@ValidatableModel cannot be applied to a type that already declares static func validations(_:)."
        case constraintRequiresStoredProperty = "@Constraint can only be applied to a stored property."
        case constraintRequiresSingleBinding = "@Constraint properties must declare exactly one stored property."
        case constraintRequiresExplicitType = "@Constraint properties must declare an explicit type."
        case constraintRequiresRule = "@Constraint requires a validation rule as its first argument."
        case constraintMessageMustBeStringLiteral = "@Constraint message must be a string literal or nil."
        case ruleNotSupportedForType = "@Constraint rule is not supported for this property type."
        case predicateTypeMismatch = "@Constraint predicate type must match the property type."
        case customConstraintRequiresType = "@Constraint(validating:with:) requires an explicit validating type."
        case customConstraintRequiresClosure = "@Constraint(validating:with:) requires a closure passed with the 'with' argument."
        case customConstraintTypeMismatch = "@Constraint(validating:with:) type must match the property type."

        var message: String { rawValue }
        var diagnosticID: MessageID { .init(domain: DiagnosticDomain.domain, id: "\(self)") }
        var severity: SwiftDiagnostics.DiagnosticSeverity { .error }
    }

    struct ValidationEntry {
        let propertyName: String
        let propertyType: TypeSyntax
        let validatorExpression: ExprSyntax
        let required: ExprSyntax?
        let message: ExprSyntax?
        let validatorName: TokenSyntax
    }

    struct PropertyKind: Equatable {
        let baseTypeName: String
        let isOptional: Bool

        var isCountable: Bool {
            if baseTypeName == "String" || baseTypeName == "Substring" {
                return true
            }

            return baseTypeName.hasPrefix("[") || baseTypeName.hasPrefix("Array<") || baseTypeName.hasPrefix("Set<")
        }

        var isRangeCompatible: Bool {
            numericTypeNames.contains(baseTypeName)
        }

        private var numericTypeNames: Set<String> {
            [
                "Int", "Int8", "Int16", "Int32", "Int64",
                "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
                "Float", "Double", "Decimal"
            ]
        }
    }
}

extension ValidatableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node, message: MacroDiagnostic.requiresStructOrClass))
            return []
        }

        if let existingValidationsMethod = declaration.memberBlock.members.first(where: hasValidationsMethod)?.decl {
            context.diagnose(
                Diagnostic(node: Syntax(existingValidationsMethod), message: MacroDiagnostic.duplicateValidationsMethod)
            )
            return []
        }

        let validations = declaration.memberBlock.members.flatMap {
            validationEntries(from: $0, context: context)
        }

        return [validationsDeclaration(for: validations)]
    }
}

extension ValidatableMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        try [
            ExtensionDeclSyntax("extension \(type): Vapor.Validatable {}")
        ]
    }
}

extension Collection {
    var onlyElement: Element? {
        count == 1 ? first : nil
    }
}
