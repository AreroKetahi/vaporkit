//
//  OpenAPIDocumentBuilderError.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 11/07/2026
//

/// Errors produced while combining discovered router metadata.
@_documentation(visibility: internal)
public enum OpenAPIDocumentBuilderError: Error, CustomStringConvertible {
    /// Multiple router descriptors use the same identifier.
    case duplicateRouter(String)
    /// A router registers a child whose descriptor was not discovered.
    case missingRouter(parent: String, child: String)
    /// Registered routers form a cycle.
    case routerCycle([String])
    /// Multiple handlers resolve to the same HTTP method and complete path.
    case duplicateOperation(method: String, path: String)

    public var description: String {
        switch self {
        case .duplicateRouter(let identifier):
            return "Duplicate OpenAPI router identifier: \(identifier)."
        case .missingRouter(let parent, let child):
            return "Router \(parent) registers \(child), but no matching OpenAPI descriptor was found."
        case .routerCycle(let identifiers):
            return "OpenAPI router registration cycle: \(identifiers.joined(separator: " -> "))."
        case .duplicateOperation(let method, let path):
            return "Duplicate OpenAPI operation: \(method.uppercased()) \(path)."
        }
    }
}
