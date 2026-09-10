# OpenAPI

Generate an OpenAPI document from the same declarations that define your routes.

## Overview

VaporKit derives paths, parameters, request bodies, responses, and schemas from
full-featured router methods. Add `OpenAPI(operationID:summary:description:tags:)`
when an operation needs explicit metadata, then export the linked router graph
without starting a Vapor application.

> Important: OpenAPI generation is an Alpha feature. Its API and generated
> output may change before a stable release.

### Describing Operations

Use the OpenAPI route annotations to override inferred operation metadata,
request bodies, and responses, or to omit a route from the document.

```swift
@OpenAPI(operationID: "createUser", summary: "Create a user", tags: ["Users"])
@OpenAPIResponse(.created, body: UserDTO.self)
@Post
func create(
    request: Request,
    @ContentBody body: CreateUserRequest
) async throws -> UserDTO {
    try await createUser(from: body, on: request.db)
}
```

For a closure route, provide types that aren't visible in its declaration:

```swift
@OpenAPIRequest(body: CreateUserRequest.self)
@OpenAPIResponse(.created, body: UserDTO.self)
#Post("users") { request in
    let input = try request.content.decode(CreateUserRequest.self)
    return try await createUser(from: input, on: request.db)
}
```

### Describing Schemas

Conform response and request models to `OpenAPISchema` or synthesize the
conformance with `OpenAPISchema()`.

```swift
@OpenAPISchema
struct UserDTO: Content {
    var id: UUID
    var name: String
    var nickname: String?
}
```

### Exporting a Document

With ``VaporApplication``, export linked router metadata without starting the
server:

```bash
swift run MyServer extract-openapi \
  --title "My API" \
  --version "1.0.0" \
  --output openapi.json
```

### Operation Metadata

- `OpenAPI(operationID:summary:description:tags:)`
- `OpenAPIRequest(body:contentType:required:)`
- `OpenAPIResponse(_:body:description:)`
- `OpenAPIIgnored()`

### Schemas

- `OpenAPISchema()`
- `OpenAPISchema`

## Topics

### Articles

- <doc:ExportOpenAPI>
