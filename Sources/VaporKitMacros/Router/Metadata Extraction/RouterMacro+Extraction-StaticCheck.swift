import SwiftSyntax

extension RouterMacro {
    static func staticCheckOverride(
        named expectedName: String,
        in attributes: AttributeListSyntax
    ) -> StaticCheckOverride? {
        attributes.lazy.compactMap { element -> AttributeSyntax? in
            guard let attribute = element.as(AttributeSyntax.self),
                  attributeName(of: attribute) == expectedName else {
                return nil
            }

            return attribute
        }.compactMap(staticCheckOverride(from:)).first
    }

    static func staticCheckOverride(from attribute: AttributeSyntax) -> StaticCheckOverride {
        guard case .argumentList(let arguments) = attribute.arguments else {
            return .error
        }

        return staticCheckOverride(from: arguments) ?? .error
    }

    static func staticCheckOverride(from macro: MacroExpansionExprSyntax) -> StaticCheckOverride {
        staticCheckOverride(from: macro.arguments) ?? .error
    }

    static func staticCheckOverride(from arguments: LabeledExprListSyntax) -> StaticCheckOverride? {
        guard let severity = arguments.first(where: { $0.label?.text == "as" })?.expression else {
            return nil
        }

        let description = severity.trimmedDescription
        if description == ".warning" || description == "StaticCheckSeverity.warning" {
            return .warning
        }
        if description == ".error" || description == "StaticCheckSeverity.error" {
            return .error
        }

        return nil
    }
}
