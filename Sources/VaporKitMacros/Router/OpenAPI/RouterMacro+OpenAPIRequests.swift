//
//  RouterMacro+OpenAPIRequests.swift
//  vaporkit
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

extension RouterMacro {
    static func explicitOpenAPIRequestBody(
        in attributes: AttributeListSyntax
    ) -> String? {
        guard let attribute = attributes.compactMap({ element in
            element.as(AttributeSyntax.self)
        }).first(where: { attributeName(of: $0) == openAPIRequestAttributeName }) else {
            return nil
        }

        let arguments: LabeledExprListSyntax
        if case .argumentList(let parsedArguments) = attribute.arguments {
            arguments = parsedArguments
        } else {
            return nil
        }
        guard let body = arguments.first(where: { $0.label?.text == "body" })?.expression else {
            return nil
        }
        let contentType = arguments.first(where: { $0.label?.text == "contentType" })?.expression
            .trimmedDescription ?? "\"application/json\""
        let required = arguments.first(where: { $0.label?.text == "required" })?.expression
            .trimmedDescription ?? "true"
        return "VaporKit._OpenAPIRequestBodyDescriptor(body: \(body.trimmedDescription), contentType: \(contentType), required: \(required))"
    }

    static func openAPIRequestBody(
        from function: FunctionDeclSyntax,
        in declaration: any DeclGroupSyntax,
        routerIdentifier: String,
        context: some MacroExpansionContext
    ) -> String? {
        if let explicit = explicitOpenAPIRequestBody(in: function.attributes) {
            return explicit
        }

        let contentParameters = function.signature.parameterClause.parameters.dropFirst().filter {
            contentAttribute(from: $0.attributes) != nil
        }
        guard contentParameters.count <= 1 else {
            context.diagnose(Diagnostic(
                node: Syntax(function),
                message: OpenAPIRequestInferenceDiagnostic()
            ))
            return nil
        }
        guard let parameter = contentParameters.first else { return nil }

        let required = parameter.defaultValue == nil && !isOptionalType(parameter.type)
        let schemaType = openAPISchemaTypeDescription(
            parameter.type,
            in: declaration,
            routerIdentifier: routerIdentifier
        )
        return "VaporKit._OpenAPIRequestBodyDescriptor(body: (\(schemaType)).self, required: \(required))"
    }

    static func openAPISchemaTypeDescription(
        _ type: TypeSyntax,
        in declaration: any DeclGroupSyntax,
        routerIdentifier: String
    ) -> String {
        let nestedTypes = Set<String>(declaration.memberBlock.members.compactMap { member -> String? in
            guard let nestedDeclaration = member.decl.asProtocol(
                (any DeclGroupSyntax).self
            ) else { return nil }
            return nominalTypeName(of: nestedDeclaration)
        })
        guard !nestedTypes.isEmpty else { return type.trimmedDescription }
        return NestedOpenAPISchemaTypeRewriter(
            nestedTypes: nestedTypes,
            routerIdentifier: routerIdentifier
        ).rewrite(type).trimmedDescription
    }

    private final class NestedOpenAPISchemaTypeRewriter: SyntaxRewriter {
        private let nestedTypes: Set<String>
        private let routerIdentifier: String

        init(nestedTypes: Set<String>, routerIdentifier: String) {
            self.nestedTypes = nestedTypes
            self.routerIdentifier = routerIdentifier
            super.init(viewMode: .sourceAccurate)
        }

        override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
            let rewritten = super.visit(node)
            guard let identifier = rewritten.as(IdentifierTypeSyntax.self),
                  nestedTypes.contains(identifier.name.text) else {
                return rewritten
            }
            return TypeSyntax(MemberTypeSyntax(
                baseType: IdentifierTypeSyntax(name: .identifier(routerIdentifier)),
                name: identifier.name,
                genericArgumentClause: identifier.genericArgumentClause
            ))
        }
    }
}
