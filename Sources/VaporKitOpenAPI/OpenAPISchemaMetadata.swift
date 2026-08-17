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
    /// The JSON value types accepted by the schema.
    ///
    /// OpenAPI encodes a single value as a string and multiple values as a
    /// JSON Schema type array.
    public var types: [OpenAPISchemaType]?

    /// The schema's sole JSON value type, if it accepts exactly one type.
    public var type: OpenAPISchemaType? {
        get { types?.count == 1 ? types?.first : nil }
        set { types = newValue.map { [$0] } }
    }
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
    /// Alternative schemas accepted by this schema.
    public var anyOf: [OpenAPISchemaItems]?
    /// Property names required on an object value.
    public var required: [String]?
    /// Creates an OpenAPI schema description.
    ///
    /// - Parameters:
    ///   - type: The JSON value type.
    ///   - format: An optional type format.
    ///   - reference: A JSON Reference to another schema.
    ///   - items: The element schema for an array.
    ///   - properties: Named schema types for object properties.
    ///   - additionalProperties: The schema for arbitrary object values.
    ///   - anyOf: Alternative schemas accepted by this schema.
    ///   - required: Required object property names.
    public init(
        type: OpenAPISchemaType? = nil,
        format: OpenAPISchemaFormat? = nil,
        reference: String? = nil,
        items: OpenAPISchemaMetadata? = nil,
        properties: [String: any OpenAPISchema.Type]? = nil,
        additionalProperties: OpenAPISchemaMetadata? = nil,
        anyOf: [OpenAPISchemaMetadata]? = nil,
        required: [String]? = nil
    ) {
        self.types = type.map { [$0] }
        self.format = format
        self.reference = reference
        self.items = items.map(OpenAPISchemaItems.init)
        self.properties = properties?.mapValues { $0.openAPISchema }
        self.additionalProperties = additionalProperties.map(OpenAPISchemaItems.init)
        self.anyOf = anyOf?.map(OpenAPISchemaItems.init)
        self.required = required
    }

    enum CodingKeys: String, CodingKey {
        case type, format, items, properties, additionalProperties, anyOf, required
        case reference = "$ref"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let type = try? container.decode(OpenAPISchemaType.self, forKey: .type) {
            types = [type]
        } else {
            types = try container.decodeIfPresent([OpenAPISchemaType].self, forKey: .type)
        }
        format = try container.decodeIfPresent(OpenAPISchemaFormat.self, forKey: .format)
        reference = try container.decodeIfPresent(String.self, forKey: .reference)
        items = try container.decodeIfPresent(OpenAPISchemaItems.self, forKey: .items)
        properties = try container.decodeIfPresent(
            [String: OpenAPISchemaMetadata].self,
            forKey: .properties
        )
        additionalProperties = try container.decodeIfPresent(
            OpenAPISchemaItems.self,
            forKey: .additionalProperties
        )
        anyOf = try container.decodeIfPresent([OpenAPISchemaItems].self, forKey: .anyOf)
        required = try container.decodeIfPresent([String].self, forKey: .required)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let types, types.count == 1 {
            try container.encode(types[0], forKey: .type)
        } else {
            try container.encodeIfPresent(types, forKey: .type)
        }
        try container.encodeIfPresent(format, forKey: .format)
        try container.encodeIfPresent(reference, forKey: .reference)
        try container.encodeIfPresent(items, forKey: .items)
        try container.encodeIfPresent(properties, forKey: .properties)
        try container.encodeIfPresent(additionalProperties, forKey: .additionalProperties)
        try container.encodeIfPresent(anyOf, forKey: .anyOf)
        try container.encodeIfPresent(required, forKey: .required)
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
