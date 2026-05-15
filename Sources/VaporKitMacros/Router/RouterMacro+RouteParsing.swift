import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension RouterMacro {
    /// Freestanding declarations and attached handlers eventually normalize into the same route spec.
    static func routeSpec(
        from expansion: MacroExpansionDeclSyntax,
        macroName: RouteMacroName
    ) -> (path: String, method: String) {
        let path = routePath(from: expansion.arguments)
        let method = routeMethod(from: expansion.arguments, macroName: macroName)
        return (path, method)
    }

    static func routeSpec(from attribute: AttributeSyntax) -> (path: String, method: String) {
        guard case let .argumentList(arguments) = attribute.arguments else {
            return ("", "")
        }

        let path = routeHandlerPath(from: arguments)
        let method = routeHandlerMethod(from: arguments)
        return (path, method)
    }

    static func routePath(from arguments: LabeledExprListSyntax) -> String {
        guard let pathArgument = arguments.first(where: { $0.label == nil }) else {
            return ""
        }

        // Freestanding route macros treat the first unlabeled literal as the URL. Omitted or nil
        // paths intentionally normalize to the empty route so the router prefix can own the URL.
        return stringLiteralValue(from: pathArgument.expression) ?? ""
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

    static func routeHandlerPath(from arguments: LabeledExprListSyntax) -> String {
        // `@RouteHandler` supports both `"users/:id"` and `"users", ":id"` styles, so every
        // unlabeled string argument is flattened into one canonical path.
        let segments = arguments
            .filter { $0.label == nil }
            .compactMap { stringLiteralValue(from: $0.expression) }
            .flatMap(pathSegments(from:))

        return segments.joined(separator: "/")
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
}
