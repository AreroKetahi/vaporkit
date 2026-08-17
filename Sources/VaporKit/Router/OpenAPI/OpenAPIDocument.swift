//
//  OpenAPIDocument.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 11/07/2026
//

import Foundation

/// An OpenAPI 3.1 document generated from VaporKit router metadata.
@_documentation(visibility: internal)
public struct OpenAPIDocument: Codable, Sendable {
    /// General information about the described API.
    public struct Info: Codable, Sendable {
        /// The human-readable API title.
        public var title: String
        /// The API version supplied to the exporter.
        public var version: String

        /// Creates an API information object.
        public init(title: String, version: String) {
            self.title = title
            self.version = version
        }
    }

    /// An HTTP operation associated with a path and method.
    public struct Operation: Codable, Sendable {
        /// A stable identifier for tools and generated clients.
        public var operationId: String?
        /// A short summary of the operation.
        public var summary: String?
        /// A detailed description of the operation.
        public var description: String?
        /// Tags used to group related operations.
        public var tags: [String]?
        /// Path and query parameters accepted by the operation.
        public var parameters: [Parameter]?
        /// The HTTP request body accepted by the operation.
        public var requestBody: RequestBody?
        /// Responses keyed by HTTP status code.
        public var responses: [String: Response]
    }

    /// A request body accepted by an operation.
    public struct RequestBody: Codable, Sendable {
        /// Whether callers must provide the request body.
        public var required: Bool
        /// Request content keyed by media type.
        public var content: [String: Response.Content]
    }

    /// A path or query parameter accepted by an operation.
    public struct Parameter: Codable, Sendable {
        /// The serialized parameter name.
        public var name: String
        /// The parameter location, such as `path` or `query`.
        public var `in`: String
        /// Whether callers must provide the parameter.
        public var required: Bool
        /// The parameter value schema.
        public var schema: OpenAPISchemaMetadata
    }

    /// A response produced by an operation.
    public struct Response: Codable, Sendable {
        /// Media-type-specific response content.
        public struct Content: Codable, Sendable {
            /// The response body schema.
            public var schema: OpenAPISchemaMetadata
        }

        /// A human-readable response description.
        public var description: String
        /// Response content keyed by media type.
        public var content: [String: Content]?
    }

    /// The OpenAPI specification version. VaporKit emits `3.1.0`.
    public var openapi: String
    /// General information about the API.
    public var info: Info
    /// Operations grouped first by path and then by lowercase HTTP method.
    public var paths: [String: [String: Operation]]

    /// Creates an OpenAPI 3.1 document.
    public init(info: Info, paths: [String: [String: Operation]]) {
        self.openapi = "3.1.0"
        self.info = info
        self.paths = paths
    }
}
