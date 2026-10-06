//
//  RouterMacro+OpenAPIParameters.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 27/03/2026
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

extension RouterMacro {

    static func openAPIParameters(
        from function: FunctionDeclSyntax,
        in declaration: any DeclGroupSyntax,
        routerIdentifier: String,
        context: some MacroExpansionContext
    ) -> [String] {
        function.signature.parameterClause.parameters.dropFirst().compactMap { parameter in
            let localName = localParameterName(from: parameter)
            let schemaType = openAPISchemaTypeDescription(
                parameter.type,
                in: declaration,
                routerIdentifier: routerIdentifier
            )
            let required = parameter.defaultValue == nil && !isOptionalType(parameter.type)
            let metadata = openAPIParameterMetadata(from: parameter.attributes)
            if let attribute = pathAttribute(from: parameter.attributes),
               let name = pathParameterName(from: attribute, defaultName: localName) {
                if metadata?.hasAllowEmptyValue == true {
                    context.diagnose(Diagnostic(
                        node: Syntax(parameter),
                        message: OpenAPIParameterDiagnostic.allowEmptyValueRequiresQuery
                    ))
                }
                return openAPIParameterExpression(
                    name: name,
                    location: "path",
                    schemaType: schemaType,
                    required: true,
                    metadata: metadata?.withoutAllowEmptyValue()
                )
            }
            if let attribute = queryAttribute(from: parameter.attributes) {
                let parsedKey = queryKeyPath(from: attribute)
                let keyPath: [String]?
                if let parsedKey {
                    keyPath = parsedKey
                } else {
                    keyPath = nil
                }
                let name = keyPath?.joined(separator: ".") ?? localName
                return openAPIParameterExpression(
                    name: name,
                    location: "query",
                    schemaType: schemaType,
                    required: required,
                    metadata: metadata
                )
            }
            if metadata != nil,
               let attribute = headerAttribute(from: parameter.attributes),
               let source = namedValueSource(from: attribute),
               let name = namedValueKey(source) {
                diagnoseAllowEmptyValue(metadata, parameter: parameter, context: context)
                return openAPIParameterExpression(
                    name: name,
                    location: "header",
                    schemaType: schemaType,
                    required: false,
                    metadata: metadata?.withoutAllowEmptyValue()
                )
            }
            if metadata != nil,
               let attribute = cookieAttribute(from: parameter.attributes),
               let source = namedValueSource(from: attribute),
               let name = namedValueKey(source) {
                diagnoseAllowEmptyValue(metadata, parameter: parameter, context: context)
                return openAPIParameterExpression(
                    name: name,
                    location: "cookie",
                    schemaType: schemaType,
                    required: required,
                    metadata: metadata?.withoutAllowEmptyValue()
                )
            }
            return nil
        }
    }

    private static func namedValueKey(_ source: NamedValueSource) -> String? {
        switch source {
        case .all: nil
        case .raw(let key), .decoding(let key), .converting(let key): key
        }
    }

    private static func diagnoseAllowEmptyValue(
        _ metadata: OpenAPIParameterMetadata?,
        parameter: FunctionParameterSyntax,
        context: some MacroExpansionContext
    ) {
        guard metadata?.hasAllowEmptyValue == true else { return }
        context.diagnose(Diagnostic(
            node: Syntax(parameter),
            message: OpenAPIParameterDiagnostic.allowEmptyValueRequiresQuery
        ))
    }

    private static func openAPIParameterExpression(
        name: String,
        location: String,
        schemaType: String,
        required: Bool,
        metadata: OpenAPIParameterMetadata? = nil
    ) -> String {
        let suffix = metadata.map {
            ", description: \($0.description), deprecated: \($0.deprecated), allowEmptyValue: \($0.allowEmptyValue), schemaModifiers: [\($0.schemaModifiers.joined(separator: ", "))]"
        } ?? ""
        return "VaporKit._OpenAPIParameterDescriptor(name: \(swiftLiteral(name)), location: \(swiftLiteral(location)), schema: (\(schemaType)).self, required: \(required)\(suffix))"
    }

    private struct OpenAPIParameterMetadata {
        var description = "nil"
        var deprecated = "false"
        var allowEmptyValue = "false"
        var schemaModifiers: [String] = []
        var hasAllowEmptyValue = false

        func withoutAllowEmptyValue() -> Self {
            var copy = self
            copy.allowEmptyValue = "false"
            copy.hasAllowEmptyValue = false
            return copy
        }
    }

    private static func openAPIParameterMetadata(
        from attributes: AttributeListSyntax
    ) -> OpenAPIParameterMetadata? {
        guard let attribute = attributes.compactMap({ $0.as(AttributeSyntax.self) }).first(where: {
            attributeName(of: $0) == "OpenAPIParameter"
        }), case .argumentList(let arguments) = attribute.arguments else { return nil }

        var metadata = OpenAPIParameterMetadata()
        var readingSchema = false
        for argument in arguments {
            switch argument.label?.text {
            case "description":
                metadata.description = argument.expression.trimmedDescription
                readingSchema = false
            case "deprecated":
                metadata.deprecated = argument.expression.trimmedDescription
                readingSchema = false
            case "allowEmptyValue":
                metadata.allowEmptyValue = argument.expression.trimmedDescription
                metadata.hasAllowEmptyValue = true
                readingSchema = false
            case "schema":
                metadata.schemaModifiers.append(argument.expression.trimmedDescription)
                readingSchema = true
            case nil where readingSchema:
                metadata.schemaModifiers.append(argument.expression.trimmedDescription)
            default:
                readingSchema = false
            }
        }
        return metadata
    }

    private enum OpenAPIParameterDiagnostic: SwiftDiagnostics.DiagnosticMessage {
        case allowEmptyValueRequiresQuery

        var message: String {
            "@OpenAPIParameter allowEmptyValue is only valid for query parameters."
        }

        var diagnosticID: MessageID {
            .init(domain: "VaporKit.OpenAPIParameter", id: "allowEmptyValueRequiresQuery")
        }

        var severity: SwiftDiagnostics::DiagnosticSeverity { .error }
    }

}
