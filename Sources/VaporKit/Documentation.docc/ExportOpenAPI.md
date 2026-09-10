# Exporting OpenAPI

Generate an OpenAPI 3.1 document from the router metadata linked into an executable.

## Overview

> Warning: OpenAPI generation is an Alpha feature.

Use ``VaporApplication`` as the executable entry point, then run its generated
`extract-openapi` command:

```swift
@main
struct MyServer: VaporApplication {
    static let manifest = VaporAppManifest()
}
```

```bash
swift run MyServer extract-openapi \
  --title "My API" \
  --version "1.0.0" \
  --output openapi.json
```

Export discovers metadata before creating a Vapor `Application`, so server
configuration and services don't start. Every router that should appear must
be linked into the executable.

### Describe a Route

Full-featured handlers provide the method, path, parameters, request body, and
return type. Add annotations only for metadata or overrides:

```swift
@OpenAPI(operationID: "getUser", summary: "Get a user", tags: ["Users"])
@OpenAPIResponse(.ok, body: UserDTO.self)
@Get(":id")
func show(request: Request, @Path id: UUID) async throws -> UserDTO {
    try await loadUser(id, on: request.db)
}
```

Use `OpenAPIRequest(body:contentType:required:)` when a closure route doesn't
expose its decoded body type, and `OpenAPIIgnored()` to omit an internal route
without changing its Vapor registration.

### Describe Schemas

Types used by parameters, bodies, and responses must conform to
`OpenAPISchema`. Synthesize a schema for a `Codable` model with
`OpenAPISchema()`:

```swift
@OpenAPISchema
struct UserDTO: Content {
    var id: UUID
    var name: String
    var nickname: String?
}
```

See <doc:OpenAPIOverview> for all metadata, schema, and document-generation
APIs. See <doc:UsingParameterInFunction> for how typed request values are
inferred from handler signatures.

### Export APIs

- `OpenAPI(operationID:summary:description:tags:)`
- `OpenAPIRequest(body:contentType:required:)`
- `OpenAPIResponse(_:body:description:)`
- `OpenAPIIgnored()`
- `OpenAPISchema()`
