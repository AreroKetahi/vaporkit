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

        for root in roots {
            try visit(
                root,
                inheritedPath: [],
                stack: [],
                routers: routers,
                paths: &paths
            )
        }

        // A graph with descriptors but no roots necessarily contains a cycle.
        if !descriptors.isEmpty, roots.isEmpty {
            let first = descriptors[0].identifier
            try visit(first, inheritedPath: [], stack: [], routers: routers, paths: &paths)
        }

        return OpenAPIDocument(
            info: .init(title: title, version: version),
            paths: paths
        )
    }

    private func visit(
        _ identifier: String,
        inheritedPath: [String],
        stack: [String],
        routers: [String: _OpenAPIRouterDescriptor],
        paths: inout [String: [String: OpenAPIDocument.Operation]]
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
                    schema: parameter.schema.openAPISchema
                )
            }
            let requestBody = handler.requestBody.map { request in
                OpenAPIDocument.RequestBody(
                    required: request.required,
                    content: [
                        request.contentType: .init(schema: request.body.openAPISchema)
                    ]
                )
            }
            let responses = Dictionary(uniqueKeysWithValues: handler.responses.map { response in
                (String(response.status), OpenAPIDocument.Response(
                    description: response.description,
                    content: response.hasBody ? [
                        "application/json": .init(
                            schema: response.body.openAPISchema
                        )
                    ] : nil
                ))
            })
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
                paths: &paths
            )
        }
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
