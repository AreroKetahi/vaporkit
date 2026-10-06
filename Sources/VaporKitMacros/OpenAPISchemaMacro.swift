import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct OpenAPISchemaMacro: ExtensionMacro {
    private static let propertyAttributeName = "OpenAPIProperty"

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) || declaration.is(ClassDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: Syntax(declaration), message: DiagnosticMessage()))
            return []
        }

        let properties = declaration.memberBlock.members.compactMap { member -> Property? in
            guard let variable = member.decl.as(VariableDeclSyntax.self),
                  !variable.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }),
                  variable.bindings.count == 1,
                  let binding = variable.bindings.first,
                  binding.accessorBlock == nil,
                  let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                  let annotation = binding.typeAnnotation
            else { return nil }

            let optional = optionalWrappedType(annotation.type)
            return Property(
                name: pattern.identifier.text,
                type: annotation.type,
                required: optional == nil,
                modifiers: schemaModifiers(
                    from: variable.attributes,
                    propertyType: annotation.type,
                    context: context
                )
            )
        }

        let renderedProperties = properties.map { property in
            "\(literal(property.name)): \(schemaExpression(for: property))"
        }.joined(separator: ",\n")
        let required = properties.filter(\.required).map { literal($0.name) }.joined(separator: ", ")
        let access = declaration.modifiers.contains { modifier in
            modifier.name.tokenKind == .keyword(.public) || modifier.name.tokenKind == .keyword(.open)
        } ? "public " : ""

        let extensionDecl: DeclSyntax = """
        extension \(type.trimmed): VaporKitOpenAPI.OpenAPISchema {
            \(raw: access)static var openAPISchemaName: String? {
                String(describing: Self.self)
            }

            \(raw: access)static var openAPISchema: VaporKitOpenAPI.OpenAPISchemaMetadata {
                var schema = VaporKitOpenAPI.OpenAPISchemaMetadata(
                    type: .object,
                    required: [\(raw: required)]
                )
                schema.properties = [
                    \(raw: renderedProperties)
                ]
                return schema
            }
        }
        """
        return [extensionDecl.cast(ExtensionDeclSyntax.self)]
    }

    private struct Property {
        let name: String
        let type: TypeSyntax
        let required: Bool
        let modifiers: [SchemaModifier]
    }

    private struct SchemaModifier {
        let kind: String
        let expression: ExprSyntax
    }

    private static func schemaModifiers(
        from attributes: AttributeListSyntax,
        propertyType: TypeSyntax,
        context: some MacroExpansionContext
    ) -> [SchemaModifier] {
        guard let attribute = attributes.compactMap({ $0.as(AttributeSyntax.self) }).first(where: {
            attributeName(of: $0) == propertyAttributeName
        }) else { return [] }
        guard case .argumentList(let arguments) = attribute.arguments else { return [] }

        var result: [SchemaModifier] = []
        var seen: Set<String> = []
        for argument in arguments {
            guard let parsed = schemaModifier(from: argument.expression) else {
                context.diagnose(Diagnostic(
                    node: Syntax(argument.expression),
                    message: PropertyDiagnostic.unsupportedAttribute
                ))
                continue
            }
            guard seen.insert(parsed.kind).inserted else {
                context.diagnose(Diagnostic(
                    node: Syntax(argument.expression),
                    message: PropertyDiagnostic.duplicateAttribute(parsed.kind)
                ))
                continue
            }
            if ["minLength", "maxLength", "pattern"].contains(parsed.kind),
               !isStringType(propertyType) {
                context.diagnose(Diagnostic(
                    node: Syntax(argument.expression),
                    message: PropertyDiagnostic.stringAttributeOnNonString(parsed.kind)
                ))
                continue
            }
            result.append(parsed)
        }

        if seen.contains("readOnly"), seen.contains("writeOnly") {
            context.diagnose(Diagnostic(
                node: Syntax(attribute),
                message: PropertyDiagnostic.conflictingAccess
            ))
            result.removeAll { $0.kind == "writeOnly" }
        }
        return result
    }

    private static func schemaModifier(from expression: ExprSyntax) -> SchemaModifier? {
        if let member = expression.as(MemberAccessExprSyntax.self) {
            let kind = member.declName.baseName.text
            guard ["deprecated", "readOnly", "writeOnly"].contains(kind) else { return nil }
            return SchemaModifier(kind: kind, expression: expression)
        }
        guard let call = expression.as(FunctionCallExprSyntax.self),
              let member = call.calledExpression.as(MemberAccessExprSyntax.self),
              call.arguments.count == 1 else { return nil }
        let kind = member.declName.baseName.text
        guard ["format", "description", "minLength", "maxLength", "pattern"].contains(kind) else {
            return nil
        }
        return SchemaModifier(kind: kind, expression: expression)
    }

    private static func schemaExpression(for property: Property) -> String {
        let base = "(\(property.type.trimmedDescription)).openAPISchema"
        guard !property.modifiers.isEmpty else { return base }
        let modifiers = property.modifiers.map(\.expression.trimmedDescription)
            .joined(separator: ", ")
        return "\(base).applying([\(modifiers)])"
    }

    private static func isStringType(_ type: TypeSyntax) -> Bool {
        if let wrapped = optionalWrappedType(type) {
            return isStringType(wrapped)
        }
        return type.trimmedDescription == "String"
    }

    private static func attributeName(of attribute: AttributeSyntax) -> String? {
        if let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self) {
            return identifier.name.text
        }
        return attribute.attributeName.as(MemberTypeSyntax.self)?.name.text
    }

    private static func optionalWrappedType(_ type: TypeSyntax) -> TypeSyntax? {
        if let optional = type.as(OptionalTypeSyntax.self) { return optional.wrappedType }
        if let optional = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) { return optional.wrappedType }
        if let identifier = type.as(IdentifierTypeSyntax.self),
           identifier.name.text == "Optional",
           let argument = identifier.genericArgumentClause?.arguments.first {
            if case .type(let wrappedType) = argument.argument {
                return wrappedType
            }
        }
        return nil
    }

    private static func literal(_ value: String) -> String {
        StringLiteralExprSyntax(content: value).trimmedDescription
    }

    private struct DiagnosticMessage: SwiftDiagnostics.DiagnosticMessage {
        var message: String { "@OpenAPISchema can only be attached to a struct or class." }
        var diagnosticID: MessageID { .init(domain: "VaporKitOpenAPI.OpenAPISchema", id: "invalidDeclaration") }
        var severity: DiagnosticSeverity { .error }
    }

    private enum PropertyDiagnostic: SwiftDiagnostics.DiagnosticMessage {
        case unsupportedAttribute
        case duplicateAttribute(String)
        case stringAttributeOnNonString(String)
        case conflictingAccess

        var message: String {
            switch self {
            case .unsupportedAttribute:
                "Unsupported @OpenAPIProperty attribute."
            case .duplicateAttribute(let name):
                "@OpenAPIProperty contains duplicate .\(name) metadata."
            case .stringAttributeOnNonString(let name):
                ".\(name) can only be applied to a String property."
            case .conflictingAccess:
                "@OpenAPIProperty cannot be both read-only and write-only."
            }
        }

        var diagnosticID: MessageID {
            let id = switch self {
            case .unsupportedAttribute: "unsupportedAttribute"
            case .duplicateAttribute: "duplicateAttribute"
            case .stringAttributeOnNonString: "stringAttributeOnNonString"
            case .conflictingAccess: "conflictingAccess"
            }
            return .init(domain: "VaporKitOpenAPI.OpenAPIProperty", id: id)
        }

        var severity: DiagnosticSeverity { .error }
    }
}
