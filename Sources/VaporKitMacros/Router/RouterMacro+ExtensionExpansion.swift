import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension RouterMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // `@Router` always turns the annotated type into a `RouteCollection`, even when every
        // registration came from existing `@RouteHandler` functions instead of freestanding macros.
        try [
            ExtensionDeclSyntax("extension \(type): Vapor.RouteCollection {}")
        ]
    }
}
