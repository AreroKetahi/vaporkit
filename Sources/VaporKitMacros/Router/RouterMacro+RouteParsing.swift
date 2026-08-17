import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension RouterMacro {
    /// Freestanding declarations and attached handlers eventually normalize into the same route spec.
    static func routeSpec(
        from expansion: MacroExpansionDeclSyntax,
        macroName: RouteMacroName
    ) -> (path: String, method: String, pathParameterStrategies: [String: PathParameterStrategy], diagnostics: [RouterPathParseDiagnostic]) {
        let parsedPath = routePath(from: expansion.arguments)
        let method = routeMethod(from: expansion.arguments, macroName: macroName)
        return (parsedPath.path, method, parsedPath.parameterStrategies, parsedPath.diagnostics)
    }

    static func routeSpec(from attribute: AttributeSyntax) -> (path: String, method: String, pathParameterStrategies: [String: PathParameterStrategy], diagnostics: [RouterPathParseDiagnostic]) {
        guard case let .argumentList(arguments) = attribute.arguments else {
            return ("", "", [:], [])
        }

        let parsedPath = routeHandlerPath(from: arguments)
        let method = routeHandlerMethod(from: arguments)
        return (parsedPath.path, method, parsedPath.parameterStrategies, parsedPath.diagnostics)
    }

    static func routeSpec(
        from attribute: AttributeSyntax,
        macroName: RouteMacroName
    ) -> (path: String, method: String, pathParameterStrategies: [String: PathParameterStrategy], diagnostics: [RouterPathParseDiagnostic]) {
        guard case let .argumentList(arguments) = attribute.arguments else {
            return ("", macroName.defaultMethod ?? "", [:], [])
        }

        let parsedPath = routePath(from: arguments)
        let method = routeMethod(from: arguments, macroName: macroName)
        return (parsedPath.path, method, parsedPath.parameterStrategies, parsedPath.diagnostics)
    }

    static func routePath(
        from arguments: LabeledExprListSyntax
    ) -> ParsedRouterPath {
        guard let pathArgument = arguments.first(where: { $0.label == nil }) else {
            return .empty
        }

        // Freestanding route macros treat the first unlabeled literal as the URL. Omitted or nil
        // paths intentionally normalize to the empty route so the router prefix can own the URL.
        return parsedRouterPath(from: pathArgument.expression)
    }

    static func routeMethod(
        from arguments: LabeledExprListSyntax,
        macroName: RouteMacroName
    ) -> String {
        if let defaultMethod = macroName.defaultMethod {
            return defaultMethod
        }

        // `#On` may omit its URL entirely, so the method must be found by label instead of index.
        guard let methodArgument = arguments.first(where: { $0.label?.text == "method" }) else {
            return ""
        }

        return memberAccessBaseName(from: methodArgument.expression)?.uppercased() ?? ""
    }

    static func routeHandlerPath(from arguments: LabeledExprListSyntax) -> ParsedRouterPath {
        // `@RouteHandler` supports both `"users/:id"` and `"users", ":id"` styles, so every
        // unlabeled string argument is flattened into one canonical path.
        var components: [String] = []
        var strategies: [String: PathParameterStrategy] = [:]
        var diagnostics: [RouterPathParseDiagnostic] = []

        for argument in arguments where argument.label == nil {
            let parsed = parsedRouterPath(from: argument.expression)
            components.append(contentsOf: pathSegments(from: parsed.path))
            diagnostics.append(contentsOf: parsed.diagnostics)
            for (name, strategy) in parsed.parameterStrategies {
                if strategies.updateValue(strategy, forKey: name) != nil {
                    diagnostics.append(.init(
                        node: Syntax(argument.expression),
                        message: .routerPathDuplicateName
                    ))
                }
            }
        }

        return .init(
            path: components.joined(separator: "/"),
            parameterStrategies: strategies,
            diagnostics: diagnostics
        )
    }

    static func routeHandlerMethod(from arguments: LabeledExprListSyntax) -> String {
        guard let methodArgument = arguments.first(where: { $0.label?.text == "method" }) else {
            return ""
        }

        return memberAccessBaseName(from: methodArgument.expression)?.uppercased() ?? ""
    }

    static func memberAccessBaseName(from expression: ExprSyntax) -> String? {
        expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
    }

    /// URL normalization deliberately strips duplicate separators so callers can mix styles freely.
    static func joinedURL(_ prefix: String?, _ path: String) -> String {
        let segments = [prefix, path]
            .compactMap { $0 }
            .flatMap(pathSegments(from:))

        return segments.joined(separator: "/")
    }

    static func pathSegments(from url: String) -> [String] {
        url.split(separator: "/")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    static func stringLiteralValue(from expression: ExprSyntax) -> String? {
        guard let literal = expression.as(StringLiteralExprSyntax.self) else {
            return nil
        }

        // Only plain string segments are supported here; interpolated strings stay non-literal.
        return literal.segments.compactMap { segment in
            segment.as(StringSegmentSyntax.self)?.content.text
        }.joined()
    }

    static func plainStringLiteralValue(from expression: ExprSyntax) -> String? {
        guard let literal = expression.as(StringLiteralExprSyntax.self),
              literal.segments.allSatisfy({ $0.is(StringSegmentSyntax.self) })
        else {
            return nil
        }

        return literal.segments.compactMap {
            $0.as(StringSegmentSyntax.self)?.content.text
        }.joined()
    }

    static func parsedRouterPath(
        from expression: ExprSyntax
    ) -> ParsedRouterPath {
        guard let literal = expression.as(StringLiteralExprSyntax.self) else {
            return .empty
        }

        var components: [String] = []
        var strategies: [String: PathParameterStrategy] = [:]
        var diagnostics: [RouterPathParseDiagnostic] = []

        for segment in literal.segments {
            if let stringSegment = segment.as(StringSegmentSyntax.self) {
                components.append(contentsOf: pathSegments(from: stringSegment.content.text))
                continue
            }

            guard let interpolation = segment.as(ExpressionSegmentSyntax.self),
                  let first = interpolation.expressions.first
            else {
                diagnostics.append(.init(node: Syntax(segment), message: .routerPathInvalidInterpolation))
                continue
            }

            guard let name = plainStringLiteralValue(from: first.expression) else {
                diagnostics.append(.init(node: Syntax(first.expression), message: .routerPathRequiresLiteralName))
                continue
            }

            guard !name.isEmpty else {
                diagnostics.append(.init(node: Syntax(first.expression), message: .routerPathEmptyName))
                continue
            }

            guard !name.contains("/"), !name.contains(":") else {
                diagnostics.append(.init(node: Syntax(first.expression), message: .routerPathInvalidName))
                continue
            }

            let strategy: PathParameterStrategy
            if first.label?.text == "key", interpolation.expressions.count == 1 {
                strategy = .label
            } else if first.label == nil,
                      interpolation.expressions.count == 2,
                      let decoding = interpolation.expressions.first(where: { $0.label?.text == "decoding" }),
                      let type = metatypeName(from: decoding.expression) {
                strategy = .decoding(type: type)
            } else if first.label == nil,
                      interpolation.expressions.count == 2,
                      let converting = interpolation.expressions.first(where: { $0.label?.text == "converting" }),
                      let type = metatypeName(from: converting.expression) {
                strategy = .converting(type: type)
            } else {
                diagnostics.append(.init(node: Syntax(interpolation), message: .routerPathInvalidInterpolation))
                continue
            }

            if strategies[name] != nil {
                diagnostics.append(.init(node: Syntax(interpolation), message: .routerPathDuplicateName))
                continue
            }

            components.append(":\(name)")
            strategies[name] = strategy
        }

        return .init(
            path: components.joined(separator: "/"),
            parameterStrategies: strategies,
            diagnostics: diagnostics
        )
    }

    static func metatypeName(from expression: ExprSyntax) -> String? {
        guard let memberAccess = expression.as(MemberAccessExprSyntax.self),
              memberAccess.declName.baseName.text == "self",
              let base = memberAccess.base
        else {
            return nil
        }

        return base.trimmedDescription
    }

    static func diagnoseRouterPath(
        _ diagnostics: [RouterPathParseDiagnostic],
        in context: some MacroExpansionContext
    ) {
        for diagnostic in diagnostics {
            context.diagnose(Diagnostic(node: diagnostic.node, message: diagnostic.message))
        }
    }
}
