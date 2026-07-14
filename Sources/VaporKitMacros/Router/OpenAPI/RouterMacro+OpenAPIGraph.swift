//
//  RouterMacro+OpenAPIGraph.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 27/03/2026
//

import SwiftSyntax

extension RouterMacro {

    static func openAPIOperationMetadata(
        from attributes: AttributeListSyntax
    ) -> (operationID: String, summary: String, description: String, tags: String) {
        guard let attribute = attributes.compactMap({ element -> AttributeSyntax? in
            guard let attribute = element.as(AttributeSyntax.self),
                  attributeName(of: attribute) == openAPIAttributeName else { return nil }
            return attribute
        }).first,
        case .argumentList(let arguments) = attribute.arguments else {
            return ("nil", "nil", "nil", "[]")
        }
        func value(_ label: String, default fallback: String = "nil") -> String {
            arguments.first(where: { $0.label?.text == label })?.expression.trimmedDescription ?? fallback
        }
        return (value("operationID"), value("summary"), value("description"), value("tags", default: "[]"))
    }

    static func openAPIRegisteredRouterIdentifiers(
        in declaration: any DeclGroupSyntax
    ) -> [String] {
        declaration.memberBlock.members.flatMap { member -> [String] in
            guard let expansion = member.decl.as(MacroExpansionDeclSyntax.self),
                  expansion.macroName.text == registerMacroName else { return [] }
            return expansion.arguments.compactMap { routerIdentifier(from: $0.expression) }
        }
    }

    static func routerIdentifier(from expression: ExprSyntax) -> String? {
        if let call = expression.as(FunctionCallExprSyntax.self) {
            return call.calledExpression.trimmedDescription
        }
        return expression.trimmedDescription.isEmpty ? nil : expression.trimmedDescription
    }

    static func swiftLiteral(_ value: String) -> String {
        StringLiteralExprSyntax(content: value).trimmedDescription
    }
}
