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
    @OpenAPIProperty(.description("Display name"), .minLength(1))
    var name: String

    @OpenAPIProperty(.format(.email), .maxLength(254))
    var email: String

    @OpenAPIProperty(.writeOnly, .minLength(8))
    var password: String?
    var nickname: String?
}
```

The Swift property type determines the OpenAPI `type`, nullability, and whether
the property is required. ``OpenAPIProperty(_:)`` only adds schema annotations
and constraints; it cannot replace the inferred type.

Available modifiers include `format`, `description`, `deprecated`, `readOnly`,
`writeOnly`, `minLength`, `maxLength`, and `pattern(regex:)`.

### Describing Parameters

Use ``OpenAPIParameter`` together with a parameter-source wrapper when an
inferred path, query, header, or cookie parameter needs additional metadata:

```swift
func search(
    request: Request,
    @OpenAPIParameter(
        description: "Search keywords",
        schema: .minLength(2), .maxLength(100)
    )
    @Query query: String
) async throws -> [UserDTO] {
    try await searchUsers(query, on: request.db)
}
```

The source wrapper still determines the parameter location and decodes the
value. The Swift type determines its schema type and required state.
`OpenAPIParameter` adds parameter-level `description`, `deprecated`, and
query-only `allowEmptyValue`, while `schema` accepts the same
``OpenAPISchemaModifier`` values used by ``OpenAPIProperty(_:)``.

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
- `OpenAPIProperty(_:)`
- `OpenAPISchemaModifier`

### Parameters

- `OpenAPIParameter`

## Topics

### Articles

- <doc:ExportOpenAPI>
