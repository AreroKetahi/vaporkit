//
//  OpenAPIDescriptors.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 11/07/2026
//

import enum Vapor.HTTPStatus

// MARK: - Section descriptor model

public struct _OpenAPIParameterDescriptor: Sendable {
    public let name: String
    public let location: String
    public let schema: any OpenAPISchema.Type
    public let required: Bool

    public init<S: OpenAPISchema>(
        name: String,
        location: String,
        schema: S.Type,
        required: Bool
    ) {
        self.name = name
        self.location = location
        self.schema = S.self
        self.required = required
    }
}

public struct _OpenAPIRequestBodyDescriptor: Sendable {
    public let body: any OpenAPISchema.Type
    public let contentType: String
    public let required: Bool

    public init<S: OpenAPISchema>(
        body: S.Type,
        contentType: String = "application/json",
        required: Bool = true
    ) {
        self.body = S.self
        self.contentType = contentType
        self.required = required
    }
}

public struct _OpenAPIResponseDescriptor: Sendable {
    public let status: UInt
    public let description: String
    public let body: any OpenAPISchema.Type

    public var hasBody: Bool {
        body != Never.self
    }

    public init<S: OpenAPISchema>(
        status: HTTPStatus,
        body: S.Type,
        description: String? = nil
    ) {
        self.status = status.code
        self.description = description ?? status.reasonPhrase
        self.body = S.self
    }
}

public struct _OpenAPIHandlerDescriptor: Sendable {
    public let identifier: String
    public let method: String
    public let path: String
    public let parameters: [_OpenAPIParameterDescriptor]
    public let requestBody: _OpenAPIRequestBodyDescriptor?
    public let responses: [_OpenAPIResponseDescriptor]
    public let operationID: String?
    public let summary: String?
    public let operationDescription: String?
    public let tags: [String]

    public init(
        identifier: String,
        method: String,
        path: String,
        parameters: [_OpenAPIParameterDescriptor] = [],
        requestBody: _OpenAPIRequestBodyDescriptor? = nil,
        responses: [_OpenAPIResponseDescriptor] = [],
        operationID: String? = nil,
        summary: String? = nil,
        description: String? = nil,
        tags: [String] = []
    ) {
        self.identifier = identifier
        self.method = method
        self.path = path
        self.parameters = parameters
        self.requestBody = requestBody
        self.responses = responses
        self.operationID = operationID
        self.summary = summary
        self.operationDescription = description
        self.tags = tags
    }
}

public struct _OpenAPIRouterDescriptor: Sendable {
    public let identifier: String
    public let path: String
    public let handlers: [_OpenAPIHandlerDescriptor]
    public let registeredRouters: [String]

    public init(
        identifier: String,
        path: String,
        handlers: [_OpenAPIHandlerDescriptor],
        registeredRouters: [String]
    ) {
        self.identifier = identifier
        self.path = path
        self.handlers = handlers
        self.registeredRouters = registeredRouters
    }
}

public typealias _OpenAPIRegisterAccessor = @convention(c) (
    _ outValue: UnsafeMutableRawPointer,
    _ type: UnsafeRawPointer,
    _ hint: UnsafeRawPointer?,
    _ reserved: UInt
) -> CBool

public typealias _OpenAPIRegisterRecord = (
    kind: UInt32,
    version: UInt32,
    accessor: _OpenAPIRegisterAccessor,
    context: UInt,
    reserved: UInt
)
