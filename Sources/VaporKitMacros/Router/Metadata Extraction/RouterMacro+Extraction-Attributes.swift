import SwiftSyntax

extension RouterMacro {
    static func routeHandlerAttribute(from attributes: AttributeListSyntax)
        -> AttributeSyntax?
    {
        attributes.compactMap { element in
            element.as(AttributeSyntax.self)
        }.first { attribute in
            attributeName(of: attribute) == routeHandlerAttributeName
        }
    }

    static func typedRouteAttribute(from attributes: AttributeListSyntax)
        -> AttributeSyntax?
    {
        attributes.compactMap { element in
            element.as(AttributeSyntax.self)
        }.first { attribute in
            guard let name = attributeName(of: attribute) else {
                return false
            }

            return RouteMacroName(rawValue: name) != nil
        }
    }

    static func pathAttribute(from attributes: AttributeListSyntax)
        -> AttributeSyntax?
    {
        attributes.compactMap { element in
            element.as(AttributeSyntax.self)
        }.first { attribute in
            attributeName(of: attribute) == typedPathAttributeName
        }
    }

    static func queryAttribute(from attributes: AttributeListSyntax)
        -> AttributeSyntax?
    {
        attributes.compactMap { element in
            element.as(AttributeSyntax.self)
        }.first { attribute in
            attributeName(of: attribute) == typedQueryAttributeName
        }
    }

    static func contentAttribute(from attributes: AttributeListSyntax)
        -> AttributeSyntax?
    {
        attributes.compactMap { element in
            element.as(AttributeSyntax.self)
        }.first { attribute in
            attributeName(of: attribute) == typedContentAttributeName
        }
    }

    static func authAttribute(from attributes: AttributeListSyntax)
        -> AttributeSyntax?
    {
        attributes.compactMap { element in
            element.as(AttributeSyntax.self)
        }.first { attribute in
            attributeName(of: attribute) == typedAuthAttributeName
        }
    }

    static func pathParameterName(
        from attribute: AttributeSyntax,
        defaultName: String
    ) -> String? {
        guard case .argumentList(let arguments) = attribute.arguments else {
            return defaultName
        }

        guard let firstArgument = arguments.first(where: { $0.label == nil }) else {
            return arguments.isEmpty ? defaultName : nil
        }

        return stringLiteralValue(from: firstArgument.expression)
    }

    static func queryKeyPath(from attribute: AttributeSyntax) -> [String]?? {
        guard case .argumentList(let arguments) = attribute.arguments else {
            return nil
        }

        guard let firstArgument = arguments.first(where: { $0.label == nil }) else {
            return arguments.isEmpty ? nil : .some(nil)
        }

        guard let key = stringLiteralValue(from: firstArgument.expression) else {
            return .some(nil)
        }

        if key.isEmpty {
            return .some(.some([""]))
        }

        let keyPath = key.split { character in
            character == "." || character == "/"
        }.map(String.init)
        return .some(.some(keyPath.isEmpty ? [key] : keyPath))
    }

    static func middlewareExpressions(from attributes: AttributeListSyntax)
        -> [ExprSyntax]
    {
        var expressions: [ExprSyntax] = []

        for element in attributes {
            guard let attribute = element.as(AttributeSyntax.self),
                attributeName(of: attribute) == middlewareAttributeName,
                case .argumentList(let arguments) = attribute.arguments
            else {
                continue
            }

            expressions.append(contentsOf: arguments.map(\.expression))
        }

        return expressions
    }

    static func hasAttribute(
        named expectedName: String,
        in attributes: AttributeListSyntax
    ) -> Bool {
        attributes.contains { element in
            guard let attribute = element.as(AttributeSyntax.self) else {
                return false
            }

            return attributeName(of: attribute) == expectedName
        }
    }

    static func attributeName(of attribute: AttributeSyntax) -> String? {
        // Attributes can surface as either plain identifiers or member types depending on syntax.
        if let identifierType = attribute.attributeName.as(
            IdentifierTypeSyntax.self
        ) {
            return identifierType.name.text
        }

        return attribute.attributeName.as(MemberTypeSyntax.self)?.name.text
    }
}
