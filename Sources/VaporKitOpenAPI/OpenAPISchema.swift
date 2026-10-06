//
//  OpenAPISchema.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 10/07/2026
//

import Foundation

/// Synthesizes ``OpenAPISchema`` conformance for a struct or class.
///
/// Each stored property must have an explicit type that also conforms to
/// ``OpenAPISchema``. Optional properties include `null` in their OpenAPI 3.1
/// type declaration and are omitted from the schema's required-property list.
@attached(
    extension,
    conformances: OpenAPISchema,
    names: named(openAPISchema), named(openAPISchemaName)
)
public macro OpenAPISchema() = #externalMacro(
    module: "VaporKitMacros",
    type: "OpenAPISchemaMacro"
)

/// A Swift type that can describe its encoded representation to OpenAPI.
///
/// Route metadata refers to schemas through this protocol instead of runtime
/// reflection. Generic initializers in the generated code make a missing
/// conformance a compile-time error.
public protocol OpenAPISchema: Codable, Sendable {
    /// The OpenAPI schema describing values of this Swift type.
    static var openAPISchema: OpenAPISchemaMetadata { get }

    /// The component name used when this schema is reusable.
    static var openAPISchemaName: String? { get }
}

extension OpenAPISchema {
    public static var openAPISchemaName: String? { nil }
}

/// Adds OpenAPI Schema Object metadata to a stored property.
///
/// Attach this marker inside a type annotated with ``OpenAPISchema()``.
/// The property's Swift type remains the source of its OpenAPI type and
/// nullability; modifiers only annotate or constrain the inferred schema.
///
/// ```swift
/// @OpenAPISchema
/// struct CreateUser: Codable {
///     @OpenAPIProperty(
///         .format(.email),
///         .description("Account email address"),
///         .maxLength(254)
///     )
///     var email: String
///
///     @OpenAPIProperty(.minLength(8), .writeOnly)
///     var password: String
/// }
/// ```
@attached(peer)
public macro OpenAPIProperty(_ modifiers: OpenAPISchemaModifier...) = #externalMacro(
    module: "VaporKitMacros",
    type: "EmptyMacro"
)
