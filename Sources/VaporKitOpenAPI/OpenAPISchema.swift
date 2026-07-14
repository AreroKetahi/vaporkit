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
/// ``OpenAPISchema``. Optional properties are emitted as nullable and omitted
/// from the schema's required-property list.
@attached(extension, conformances: OpenAPISchema, names: named(openAPISchema))
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
}
