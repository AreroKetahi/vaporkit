import SwiftSyntax

extension RouterMacro {
    static func closureParameterCount(in closure: ClosureExprSyntax) -> Int {
        guard let parameterClause = closure.signature?.parameterClause else {
            return 0
        }

        if let shorthand = parameterClause.as(
            ClosureShorthandParameterListSyntax.self
        ) {
            return shorthand.count
        }

        if let explicit = parameterClause.as(ClosureParameterClauseSyntax.self)
        {
            return explicit.parameters.count
        }

        return 0
    }

    static func closureRequestKeyword(from closure: ClosureExprSyntax)
        -> String?
    {
        guard let parameterClause = closure.signature?.parameterClause else {
            return nil
        }

        if let shorthand = parameterClause.as(
            ClosureShorthandParameterListSyntax.self
        ) {
            return shorthand.first?.name.text
        }

        if let explicit = parameterClause.as(ClosureParameterClauseSyntax.self)
        {
            guard let firstParameter = explicit.parameters.first else {
                return nil
            }

            return (firstParameter.secondName ?? firstParameter.firstName).text
        }

        return nil
    }

    static func closureReturnType(from closure: ClosureExprSyntax) -> String? {
        closure.signature?.returnClause?.type.trimmedDescription
    }
}
