//
//  OpenAPIDocumentBuilder.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 11/07/2026
//

import Foundation

/// Combines router descriptors into an ``OpenAPIDocument``.
@_documentation(visibility: internal)
public struct OpenAPIDocumentBuilder: Sendable {
    /// Creates a document builder.
    public init() {}

    /// Builds an OpenAPI document from discovered or explicitly supplied routers.
    ///
    /// - Parameters:
    ///   - title: The title stored in the document's info object.
    ///   - version: The API version stored in the info object.
    ///   - descriptors: Router metadata to combine. The default discovers
    ///     metadata linked into the current executable.
    /// - Returns: A complete OpenAPI 3.1 document.
    /// - Throws: ``OpenAPIDocumentBuilderError`` when the router graph is invalid.
    public func build(
        title: String,
        version: String,
        descriptors: [_OpenAPIRouterDescriptor] = _OpenAPIDiscovery.discover()
    ) throws -> OpenAPIDocument {
        var routers: [String: _OpenAPIRouterDescriptor] = [:]
        for descriptor in descriptors {
            guard routers.updateValue(descriptor, forKey: descriptor.identifier) == nil else {
                throw OpenAPIDocumentBuilderError.duplicateRouter(descriptor.identifier)
            }
        }

        let children = Set(descriptors.flatMap(\.registeredRouters))
        let roots = descriptors.map(\.identifier).filter { !children.contains($0) }.sorted()
        var paths: [String: [String: OpenAPIDocument.Operation]] = [:]
        var schemas: [String: OpenAPISchemaMetadata] = [:]

        for root in roots {
            try visit(
                root,
                inheritedPath: [],
                stack: [],
                routers: routers,
                paths: &paths,
                schemas: &schemas
            )
        }

        // A graph with descriptors but no roots necessarily contains a cycle.
        if !descriptors.isEmpty, roots.isEmpty {
            let first = descriptors[0].identifier
            try visit(
                first,
                inheritedPath: [],
                stack: [],
                routers: routers,
                paths: &paths,
                schemas: &schemas
            )
        }

        return OpenAPIDocument(
            info: .init(title: title, version: version),
            paths: paths,
            components: schemas.isEmpty ? nil : .init(schemas: schemas)
        )
    }

    private func visit(
        _ identifier: String,
        inheritedPath: [String],
        stack: [String],
        routers: [String: _OpenAPIRouterDescriptor],
        paths: inout [String: [String: OpenAPIDocument.Operation]],
        schemas: inout [String: OpenAPISchemaMetadata]
    ) throws {
        guard let router = routers[identifier] else {
            throw OpenAPIDocumentBuilderError.missingRouter(
                parent: stack.last ?? "<root>",
                child: identifier
            )
        }
        if let cycleStart = stack.firstIndex(of: identifier) {
            throw OpenAPIDocumentBuilderError.routerCycle(
                Array(stack[cycleStart...]) + [identifier]
            )
        }

        let routerPath = inheritedPath + pathSegments(router.path)
        for handler in router.handlers {
            let path = renderedOpenAPIPath(routerPath + pathSegments(handler.path))
            let method = handler.method.lowercased()
            guard paths[path]?[method] == nil else {
                throw OpenAPIDocumentBuilderError.duplicateOperation(method: method, path: path)
            }

            let parameters = handler.parameters.map { parameter in
                OpenAPIDocument.Parameter(
                    name: parameter.name,
                    in: parameter.location,
                    required: parameter.location == "path" || parameter.required,
                    description: parameter.description,
                    deprecated: parameter.deprecated ? true : nil,
                    allowEmptyValue: parameter.allowEmptyValue ? true : nil,
                    schema: referencedSchema(parameter.schema, schemas: &schemas)
                        .applying(parameter.schemaModifiers)
                )
            }
            let requestBody = handler.requestBody.map { request in
                OpenAPIDocument.RequestBody(
                    required: request.required,
                    content: [
                        request.contentType: .init(
                            schema: referencedSchema(request.body, schemas: &schemas)
                        )
                    ]
                )
            }
            var responses: [String: OpenAPIDocument.Response] = [:]
            for response in handler.responses {
                let status = String(response.status)
                guard responses[status] == nil else {
                    throw OpenAPIDocumentBuilderError.duplicateResponse(
                        status: response.status,
                        method: method,
                        path: path
                    )
                }
                responses[status] = OpenAPIDocument.Response(
                    description: response.description,
                    content: response.hasBody ? [
                        "application/json": .init(
                            schema: referencedSchema(response.body, schemas: &schemas)
                        )
                    ] : nil
                )
            }
            let effectiveResponses = responses.isEmpty
                ? ["200": OpenAPIDocument.Response(description: "OK", content: nil)]
                : responses

            paths[path, default: [:]][method] = OpenAPIDocument.Operation(
                operationId: handler.operationID,
                summary: handler.summary,
                description: handler.operationDescription,
                tags: handler.tags.isEmpty ? nil : handler.tags,
                parameters: parameters.isEmpty ? nil : parameters,
                requestBody: requestBody,
                responses: effectiveResponses
            )
        }

        for child in router.registeredRouters {
            guard routers[child] != nil else {
                throw OpenAPIDocumentBuilderError.missingRouter(parent: identifier, child: child)
            }
            try visit(
                child,
                inheritedPath: routerPath,
                stack: stack + [identifier],
                routers: routers,
                paths: &paths,
                schemas: &schemas
            )
        }
    }

    private func referencedSchema(
        _ type: any OpenAPISchema.Type,
        schemas: inout [String: OpenAPISchemaMetadata]
    ) -> OpenAPISchemaMetadata {
        guard let name = type.openAPISchemaName else { return type.openAPISchema }
        schemas[name] = type.openAPISchema
        let escapedName = name.replacingOccurrences(of: "~", with: "~0")
            .replacingOccurrences(of: "/", with: "~1")
        return OpenAPISchemaMetadata(reference: "#/components/schemas/\(escapedName)")
    }

    private func pathSegments(_ path: String) -> [String] {
        path.split(separator: "/").map(String.init).filter { !$0.isEmpty }
    }

    private func renderedOpenAPIPath(_ segments: [String]) -> String {
        "/" + segments.map { segment in
            segment.hasPrefix(":") ? "{\(segment.dropFirst())}" : segment
        }.joined(separator: "/")
    }

}
