//
//  OpenAPIExporter.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 11/07/2026
//

import Foundation

/// Encodes and writes OpenAPI documents generated from router metadata.
@_documentation(visibility: internal)
public enum OpenAPIExporter {
    /// Generates JSON data for an OpenAPI document.
    ///
    /// - Parameters:
    ///   - title: The API title.
    ///   - version: The API version.
    ///   - descriptors: Router metadata to export.
    ///   - prettyPrinted: Whether to format the JSON for human readability.
    /// - Returns: UTF-8 OpenAPI JSON data with deterministically sorted keys.
    public static func data(
        title: String,
        version: String,
        descriptors: [_OpenAPIRouterDescriptor] = _OpenAPIDiscovery.discover(),
        prettyPrinted: Bool = true
    ) throws -> Data {
        let document = try OpenAPIDocumentBuilder().build(
            title: title,
            version: version,
            descriptors: descriptors
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = prettyPrinted ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
        return try encoder.encode(document)
    }

    /// Writes an OpenAPI document to a file URL.
    ///
    /// Parent directories must already exist. The command-line tool creates its
    /// output directory before calling this method.
    public static func export(
        to url: URL,
        title: String,
        version: String,
        descriptors: [_OpenAPIRouterDescriptor] = _OpenAPIDiscovery.discover()
    ) throws {
        try data(title: title, version: version, descriptors: descriptors).write(to: url)
    }
}
