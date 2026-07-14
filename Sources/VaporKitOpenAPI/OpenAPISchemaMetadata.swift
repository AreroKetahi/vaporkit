//
//  OpenAPISchemaMetadata.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 11/07/2026
//

import Foundation

/// A codable representation of an OpenAPI Schema Object.
///
/// Use this type when implementing ``OpenAPISchema`` manually. Most model
/// types can use the ``OpenAPISchema()`` macro instead.
public struct OpenAPISchemaMetadata: Codable, Hashable, Sendable {
    /// The JSON value type, such as `object`, `array`, or `string`.
    public var type: OpenAPISchemaType?
    /// An optional format refining ``type``, such as `uuid` or `int64`.
    public var format: OpenAPISchemaFormat?
    /// A JSON Reference to another schema.
    public var reference: String?
    /// The element schema when ``type`` is `array`.
    public var items: OpenAPISchemaItems?
    /// Named properties when ``type`` is `object`.
    public var properties: [String: OpenAPISchemaMetadata]?
    /// The schema accepted for arbitrary object property values.
    public var additionalProperties: OpenAPISchemaItems?
    /// Property names required on an object value.
    public var required: [String]?
    /// Whether the schema also accepts `null`.
    public var nullable: Bool

    /// Creates an OpenAPI schema description.
    ///
    /// - Parameters:
    ///   - type: The JSON value type.
    ///   - format: An optional type format.
    ///   - reference: A JSON Reference to another schema.
    ///   - items: The element schema for an array.
    ///   - properties: Named schema types for object properties.
    ///   - additionalProperties: The schema for arbitrary object values.
    ///   - required: Required object property names.
    ///   - nullable: Whether the value may be `null`.
    public init(
        type: OpenAPISchemaType? = nil,
        format: OpenAPISchemaFormat? = nil,
        reference: String? = nil,
        items: OpenAPISchemaMetadata? = nil,
        properties: [String: any OpenAPISchema.Type]? = nil,
        additionalProperties: OpenAPISchemaMetadata? = nil,
        required: [String]? = nil,
        nullable: Bool = false
    ) {
        self.type = type
        self.format = format
        self.reference = reference
        self.items = items.map(OpenAPISchemaItems.init)
        self.properties = properties?.mapValues { $0.openAPISchema }
        self.additionalProperties = additionalProperties.map(OpenAPISchemaItems.init)
        self.required = required
        self.nullable = nullable
    }

    enum CodingKeys: String, CodingKey {
        case type, format, items, properties, additionalProperties, required, nullable
        case reference = "$ref"
    }
}

/// A reference container used for recursive schema fields.
///
/// The container encodes transparently as its underlying schema. It exists to
/// allow recursive fields such as `items` and `additionalProperties` in the
/// value-based ``OpenAPISchemaMetadata`` model.
@_documentation(visibility: internal)
public final class OpenAPISchemaItems: Codable, Hashable, @unchecked Sendable {
    /// The contained schema.
    public let schema: OpenAPISchemaMetadata

    /// Wraps a schema for use in a recursive schema field.
    public init(_ schema: OpenAPISchemaMetadata) {
        self.schema = schema
    }

    public static func == (lhs: OpenAPISchemaItems, rhs: OpenAPISchemaItems) -> Bool {
        lhs.schema == rhs.schema
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(schema)
    }

    public required init(from decoder: any Decoder) throws {
        schema = try OpenAPISchemaMetadata(from: decoder)
    }

    public func encode(to encoder: any Encoder) throws {
        try schema.encode(to: encoder)
    }
}
