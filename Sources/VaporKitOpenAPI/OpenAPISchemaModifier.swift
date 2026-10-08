//
//  OpenAPISchemaModifier.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 06/10/2026
//

/// Metadata and constraints applied without replacing an inferred schema type.
public enum OpenAPISchemaModifier: Sendable, Hashable {
    /// Refines the representation of a value, such as `email` or `uuid`.
    case format(OpenAPISchemaFormat)
    /// Declares how string content is encoded.
    case contentEncoding(OpenAPIContentEncoding)
    /// Provides a human-readable explanation of the value.
    case description(String)
    /// Marks the value as deprecated.
    case deprecated
    /// Marks a property as present only in responses.
    case readOnly
    /// Marks a property as present only in requests.
    case writeOnly
    /// Sets the minimum accepted string length.
    case minLength(Int)
    /// Sets the maximum accepted string length.
    case maxLength(Int)
    /// Requires a string to match a regular expression.
    case pattern(regex: String)
}
