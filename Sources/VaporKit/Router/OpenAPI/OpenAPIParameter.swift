//
//  OpenAPIParameter.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 06/10/2026
//

import Foundation

/// Adds OpenAPI metadata to a request parameter without changing how its value is decoded.
///
/// Place this wrapper before a parameter source such as ``Query`` or ``Path``:
///
/// ```swift
/// func search(
///     request: Request,
///     @OpenAPIParameter(
///         description: "Search keywords",
///         schema: .minLength(2), .maxLength(100)
///     )
///     @Query query: String
/// ) async throws -> [Result] {
///     // ...
/// }
/// ```
///
/// VaporKit infers the OpenAPI type and whether the parameter is required from
/// the Swift declaration. The values passed to `schema` only annotate or
/// constrain that inferred schema.
@propertyWrapper
public struct OpenAPIParameter<Value> {
    /// The value decoded by the underlying parameter-source wrapper.
    public let wrappedValue: Value

    /// Creates OpenAPI metadata for a request parameter.
    ///
    /// - Parameters:
    ///   - wrappedValue: The value supplied by the underlying wrapper.
    ///   - description: A human-readable explanation of the parameter.
    ///   - deprecated: Whether clients should stop using the parameter.
    ///   - allowEmptyValue: Whether an empty query value is allowed. This is
    ///     valid only for query parameters.
    ///   - schema: Annotations and constraints applied to the inferred schema.
    public init(
        wrappedValue: Value,
        description: String? = nil,
        deprecated: Bool = false,
        allowEmptyValue: Bool = false,
        schema: OpenAPISchemaModifier...
    ) {
        self.wrappedValue = wrappedValue
    }
}

extension OpenAPIParameter: Decodable where Value: Decodable {
    public init(from decoder: any Decoder) throws {
        self.wrappedValue = try .init(from: decoder)
    }
}

extension OpenAPIParameter: Encodable where Value: Encodable {
    public func encode(to encoder: any Encoder) throws {
        try self.wrappedValue.encode(to: encoder)
    }
}

extension OpenAPIParameter: CustomStringConvertible where Value: CustomStringConvertible {
    public var description: String {
        wrappedValue.description
    }
}

extension OpenAPIParameter: LosslessStringConvertible where Value: LosslessStringConvertible {
    public init?(_ description: String) {
        guard let wrappedValue = Value(description) else {
            return nil
        }

        self.wrappedValue = wrappedValue
    }
}
