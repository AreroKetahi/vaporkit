import SwiftSyntax

extension RouterMacro {
    static func routeHandlerRequestKeyword(
        from signature: FunctionSignatureSyntax
    ) -> String? {
        let parameters = signature.parameterClause.parameters
        guard let firstParameter = parameters.first else {
            return nil
        }

        // For declarations like `_ req: Request`, use the second name because it is the local one.
        if let secondName = firstParameter.secondName {
            return secondName.text
        }

        return firstParameter.firstName.text
    }

    static func typedRouteRequestParameter(
        from signature: FunctionSignatureSyntax
    ) -> FunctionParameterMetadata? {
        guard let firstParameter = signature.parameterClause.parameters.first,
              isRequestParameter(firstParameter)
        else {
            return nil
        }

        return FunctionParameterMetadata(
            externalName: externalParameterName(from: firstParameter),
            localName: localParameterName(from: firstParameter)
        )
    }

    static func isRequestParameter(_ parameter: FunctionParameterSyntax) -> Bool {
        let typeName = parameter.type.trimmedDescription.filter {
            !$0.isWhitespace
        }
        return typeName == "Request" || typeName == "Vapor.Request"
    }

    static func externalParameterName(from parameter: FunctionParameterSyntax) -> String? {
        let firstName = parameter.firstName.text
        return firstName == "_" ? nil : firstName
    }

    static func localParameterName(from parameter: FunctionParameterSyntax) -> String {
        parameter.secondName?.text ?? parameter.firstName.text
    }

    static func isSupportedRouteHandlerSignature(
        _ signature: FunctionSignatureSyntax
    ) -> Bool {
        let parameters = signature.parameterClause.parameters
        guard parameters.count == 1,
            let firstParameter = parameters.first
        else {
            return false
        }

        // Validation intentionally stays syntax-based: a single Request/Vapor.Request parameter is
        // the minimum contract needed for registration and body analysis.
        let typeName = firstParameter.type.trimmedDescription.filter {
            !$0.isWhitespace
        }
        return typeName == "Request" || typeName == "Vapor.Request"
    }
}
