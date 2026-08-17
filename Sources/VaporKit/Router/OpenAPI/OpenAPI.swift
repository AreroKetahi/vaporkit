//
//  OpenAPI.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 10/07/2026
//

import Foundation
import enum Vapor.HTTPStatus

/// Excludes a router or route handler from generated OpenAPI documents.
///
/// This attribute only affects OpenAPI metadata. The route remains registered
/// with Vapor and continues to handle requests normally.
@attached(peer)
public macro OpenAPIIgnored() = #externalMacro(
    module: "VaporKitMacros",
    type: "EmptyMacro")

/// Overrides or supplies the request body schema for a route.
///
/// Typed handlers infer this metadata from a single ``ContentBody`` parameter.
/// Use this attribute for closure routes or to override the inferred schema,
/// media type, or required flag.
@attached(peer)
public macro OpenAPIRequest<S: OpenAPISchema>(
    body: S.Type,
    contentType: String = "application/json",
    required: Bool = true
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

/// Overrides the inferred response status, body schema, or description.
///
/// When `status` is omitted it defaults to `200 OK`. Supplying `body` replaces
/// the handler's inferred return type and requires the supplied type to conform
/// to ``OpenAPISchema``.
@attached(peer)
public macro OpenAPIResponse<S: OpenAPISchema>(
    _ status: HTTPStatus = .ok,
    body: S.Type,
    description: String? = nil
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

/// Overrides response metadata while retaining the handler's inferred body type.
///
/// Use this overload to change only the HTTP status or description. When the
/// handler's return type cannot be inferred, the response is emitted without a
/// body schema.
@attached(peer)
public macro OpenAPIResponse(
    _ status: HTTPStatus = .ok,
    description: String? = nil
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

/// Adds operation-level metadata that cannot be inferred from a route declaration.
///
/// VaporKit already derives the HTTP method, path, parameters, and default
/// response from the route declaration. Use this attribute for descriptive
/// information intended for generated documentation and client tools.
@attached(peer)
public macro OpenAPI(
    operationID: String? = nil,
    summary: String? = nil,
    description: String? = nil,
    tags: [String] = []
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")
