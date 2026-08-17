import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct OpenAPISchemaMacro: ExtensionMacro {
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
                required: optional == nil
            )
        }

        let renderedProperties = properties.map { property in
            "\(literal(property.name)): \(property.type.trimmedDescription).self"
        }.joined(separator: ",\n")
        let required = properties.filter(\.required).map { literal($0.name) }.joined(separator: ", ")
        let access = declaration.modifiers.contains { modifier in
            modifier.name.tokenKind == .keyword(.public) || modifier.name.tokenKind == .keyword(.open)
        } ? "public " : ""

        let extensionDecl: DeclSyntax = """
        extension \(type.trimmed): VaporKitOpenAPI.OpenAPISchema {
            \(raw: access)static var openAPISchema: VaporKitOpenAPI.OpenAPISchemaMetadata {
                VaporKitOpenAPI.OpenAPISchemaMetadata(
                    type: .object,
                    properties: [
                        \(raw: renderedProperties)
                    ],
                    required: [\(raw: required)]
                )
            }
        }
        """
        return [extensionDecl.cast(ExtensionDeclSyntax.self)]
    }

    private struct Property {
        let name: String
        let type: TypeSyntax
        let required: Bool
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
}
