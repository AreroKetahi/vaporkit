//
//  RouterMacro+OpenAPIParameters.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 27/03/2026
//

import SwiftSyntax

extension RouterMacro {

    static func openAPIParameters(
        from function: FunctionDeclSyntax,
        in declaration: any DeclGroupSyntax,
        routerIdentifier: String
    ) -> [String] {
        function.signature.parameterClause.parameters.dropFirst().compactMap { parameter in
            let localName = localParameterName(from: parameter)
            let schemaType = openAPISchemaTypeDescription(
                parameter.type,
                in: declaration,
                routerIdentifier: routerIdentifier
            )
            let required = parameter.defaultValue == nil && !isOptionalType(parameter.type)
            if let attribute = pathAttribute(from: parameter.attributes),
               let name = pathParameterName(from: attribute, defaultName: localName) {
                return openAPIParameterExpression(
                    name: name, location: "path", schemaType: schemaType, required: true
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
                    name: name, location: "query", schemaType: schemaType, required: required
                )
            }
            return nil
        }
    }

    static func openAPIParameterExpression(
        name: String,
        location: String,
        schemaType: String,
        required: Bool
    ) -> String {
        "VaporKit._OpenAPIParameterDescriptor(name: \(swiftLiteral(name)), location: \(swiftLiteral(location)), schema: (\(schemaType)).self, required: \(required))"
    }

}
