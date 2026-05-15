import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension RouterMacro {
    static func validateRequiredParameters(
        in functions: [FunctionMetadata],
        forwardedParameters: Set<String>,
        context: some MacroExpansionContext
    ) {
        for function in functions {
            guard !function.disablesParameterCheck else {
                continue
            }

            // Freestanding handlers may use either an explicit request name or shorthand `$0`.
            let availableParameters = Set(routeParameterNames(from: function.path))
                .union(forwardedParameters)
            let requestNames = acceptedRequestNames(for: function.requestKeyword)
            let visitor = RequiredParameterVisitor(acceptedRequestNames: requestNames)
            visitor.walk(Syntax(function.content))

            diagnoseMissingRequiredParameters(
                visitor.requiredParameters,
                availableParameters: availableParameters,
                context: context
            )
        }
    }

    static func validateRequiredParameters(
        in handlerMethods: [HandlerMethodMetadata],
        forwardedParameters: Set<String>,
        context: some MacroExpansionContext
    ) {
        for handlerMethod in handlerMethods {
            guard !handlerMethod.disablesParameterCheck else {
                continue
            }

            guard let body = handlerMethod.body else {
                continue
            }

            // Route handler functions only accept one validated request parameter name.
            let availableParameters = Set(routeParameterNames(from: handlerMethod.path))
                .union(forwardedParameters)
            let visitor = RequiredParameterVisitor(
                acceptedRequestNames: [handlerMethod.requestKeyword]
            )
            visitor.walk(Syntax(body))

            diagnoseMissingRequiredParameters(
                visitor.requiredParameters,
                availableParameters: availableParameters,
                context: context
            )
        }
    }

    static func diagnoseMissingRequiredParameters(
        _ requiredParameters: [RequiredParameterAccess],
        availableParameters: Set<String>,
        context: some MacroExpansionContext
    ) {
        for requiredParameter in requiredParameters where !availableParameters.contains(requiredParameter.name) {
            // The whole purpose of this check is to turn an assumed runtime contract into a
            // compile-time failure as soon as a route path and handler body drift apart.
            context.diagnose(
                Diagnostic(
                    node: requiredParameter.syntax,
                    message: RouteMacroDiagnostic.requiredParameterMissingFromRoute
                )
            )
        }
    }

    static func acceptedRequestNames(for requestKeyword: String?) -> Set<String> {
        var result: Set<String> = []
        if let requestKeyword {
            result.insert(requestKeyword)
        }
        if requestKeyword == nil {
            // Freestanding route closures without an explicit parameter can still reference `$0`.
            result.insert("$0")
        }
        return result
    }

    static func routeParameterNames(from url: String) -> [String] {
        pathSegments(from: url).compactMap { segment in
            guard segment.hasPrefix(":") else {
                return nil
            }

            // Vapor treats `:id` as a named path parameter; the validator only needs the raw name.
            return String(segment.dropFirst())
        }
    }
}
