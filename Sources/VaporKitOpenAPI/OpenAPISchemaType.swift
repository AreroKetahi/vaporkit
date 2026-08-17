//
//  OpenAPISchemaType.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 11/07/2026
//

import Foundation

/// The JSON value type represented by an OpenAPI schema.
public enum OpenAPISchemaType: String, Codable, Hashable, Sendable {
    case null
    case boolean
    case object
    case array
    case number
    case string
    case integer
}

/// A format that further refines an OpenAPI schema type.
///
/// OpenAPI allows custom format names, so this type provides constants for
/// common formats while remaining extensible through ``init(rawValue:)``.
public struct OpenAPISchemaFormat: RawRepresentable, Codable, Hashable, Sendable,
    ExpressibleByStringLiteral
{
    /// The format name encoded into the OpenAPI document.
    public let rawValue: String

    /// Creates a schema format from its OpenAPI name.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Creates a custom schema format from a string literal.
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(String.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    /// The UUID string format.
    public static let uuid = Self(rawValue: "uuid")
    /// The RFC 3339 date-time string format.
    public static let dateTime = Self(rawValue: "date-time")
    /// A signed 32-bit integer format.
    public static let int32 = Self(rawValue: "int32")
    /// A signed 64-bit integer format.
    public static let int64 = Self(rawValue: "int64")
    /// A single-precision floating-point format.
    public static let float = Self(rawValue: "float")
    /// A double-precision floating-point format.
    public static let double = Self(rawValue: "double")
}
