//
//  RouterMacro+OpenAPIResponses.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 27/03/2026
//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

extension RouterMacro {

    static func inferableOpenAPIResponseType(_ type: String) -> String? {
        guard !type.hasPrefix("some "), !type.hasPrefix("any ") else { return nil }
        return type
    }

    static func diagnoseUninferableOpenAPIResponse(
        _ inferredResponseType: String?,
        attributes: AttributeListSyntax,
        node: Syntax,
        context: some MacroExpansionContext
    ) {
        guard inferredResponseType == nil,
              !hasExplicitOpenAPIResponse(in: attributes) else { return }
        context.diagnose(Diagnostic(node: node, message: OpenAPIInferenceDiagnostic()))
    }

    static func hasExplicitOpenAPIResponse(in attributes: AttributeListSyntax) -> Bool {
        attributes.contains { element in
            guard let attribute = element.as(AttributeSyntax.self),
                  attributeName(of: attribute) == openAPIResponseAttributeName else { return false }
            return true
        }
    }

    static func openAPIHandlerExpression(
        identifier: String,
        method: String,
        path: String,
        parameters: [String],
        requestBody: String?,
        inferredResponseType: String?,
        attributes: AttributeListSyntax
    ) -> String {
        let responseAttributes = attributes.compactMap { element -> AttributeSyntax? in
            guard let attribute = element.as(AttributeSyntax.self),
                  attributeName(of: attribute) == openAPIResponseAttributeName else { return nil }
            return attribute
        }
        let responses = responseAttributes.compactMap { attribute -> String? in
            let arguments: LabeledExprListSyntax
            if case .argumentList(let parsedArguments) = attribute.arguments {
                arguments = parsedArguments
            } else {
                arguments = []
            }
            let status = arguments.first(where: { $0.label == nil })?.expression.trimmedDescription ?? ".ok"
            let body = arguments.first(where: { $0.label?.text == "body" })?.expression.trimmedDescription
                ?? inferredResponseType.map { "\($0).self" }
                ?? "Never.self"
            let description = arguments.first(where: { $0.label?.text == "description" })?.expression
            let renderedDescription = description.map { ", description: \($0.trimmedDescription)" } ?? ""
            return "VaporKit._OpenAPIResponseDescriptor(status: \(status), body: \(body)\(renderedDescription))"
        }
        let effectiveResponses: [String]
        if responseAttributes.isEmpty, let inferredResponseType {
            effectiveResponses = [
                "VaporKit._OpenAPIResponseDescriptor(status: .ok, body: \(inferredResponseType).self)"
            ]
        } else {
            effectiveResponses = responses
        }
        let metadata = openAPIOperationMetadata(from: attributes)
        let renderedRequestBody = requestBody.map { ", requestBody: \($0)" } ?? ""
        return "VaporKit._OpenAPIHandlerDescriptor(identifier: \(swiftLiteral(identifier)), method: \(swiftLiteral(method)), path: \(swiftLiteral(path)), parameters: [\(parameters.joined(separator: ", "))]\(renderedRequestBody), responses: [\(effectiveResponses.joined(separator: ", "))], operationID: \(metadata.operationID), summary: \(metadata.summary), description: \(metadata.description), tags: \(metadata.tags))"
    }

}
