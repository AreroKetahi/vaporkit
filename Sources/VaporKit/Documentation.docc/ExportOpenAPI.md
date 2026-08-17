# Export OpenAPI (Alpha)

Generate an OpenAPI 3.1 JSON document from a Vapor application executable.

## Overview

> Warning: OpenAPI export is currently an Alpha feature. Its generated document
> shape, schema inference rules, and public APIs may change before stabilization.

The `extract-openapi` command generates the document without starting a Vapor
`Application` or registering a ConsoleKit command. Router declarations only
need to be linked into the server executable.

## Export a Server Executable

Use ``VaporApplication`` as the server entry point:

```swift
@main
struct MyServer: VaporApplication {
    static let manifest = VaporAppManifest()
}
```

Run the command on the compiled server executable:

```bash
./.build/release/MyServer extract-openapi \
  --title "My API" \
  --version "1.0.0" \
  --output openapi.json
```

Metadata is discovered within the server process, before a Vapor `Application`
is created, so the server and its application services are not started.

## Describe Schema Types

Route and DTO targets that only need schema declarations may depend on the
`VaporKitOpenAPI` product directly. That module provides `OpenAPISchema`, its
macro, metadata types, and standard conformances without depending on Vapor.
Applications that import `VaporKit` receive the same API through re-export.

Types used by route parameters, request bodies, and
``OpenAPIResponse(_:body:description:)`` must conform to ``OpenAPISchema``.
The protocol also requires `Codable`. Attach ``OpenAPISchema()`` to a Codable
struct or class to synthesize its schema from stored properties.

```swift
@OpenAPISchema
struct UserDTO: Content {
    var id: UUID
    var name: String
    var nickname: String?
    var scores: [Int]
}
```

Every stored property type must also conform to ``OpenAPISchema``. A model with
an unsupported property type fails to compile instead of silently producing an
incomplete schema.

Optional values use an OpenAPI 3.1 JSON Schema type union that includes
`null`. Optional stored properties are also omitted from the generated
`required` array.

VaporKit includes schema conformances for these common shapes:

- `String` and `Bool`
- `Int`, `Int32`, and `Int64`
- `Float` and `Double`
- `UUID` and `Date`
- `Optional` when its wrapped type conforms
- `Array` when its element type conforms
- `Dictionary<String, Value>` when its value type conforms

## Describe Operations and Responses

Typed handlers already provide the HTTP method, local path, path parameters,
query parameters, and a request body declared with ``ContentBody``. Their Swift
types are used directly as schemas, so a missing ``OpenAPISchema`` conformance
is reported by the compiler. Use
``OpenAPI(operationID:summary:description:tags:)`` for descriptive operation
metadata and ``OpenAPIResponse(_:body:description:)`` for response status and
body schema.

```swift
@Router("users")
struct UserRoutes {
    @OpenAPI(
        operationID: "getUser",
        summary: "Get a user",
        description: "Returns a user by identifier.",
        tags: ["Users"]
    )
    @OpenAPIResponse(
        .ok,
        body: UserDTO.self,
        description: "The requested user."
    )
    @Get(":id")
    func show(
        _ request: Request,
        @Path id: UUID,
        @Query("include.profile") includeProfile: Bool?
    ) async throws -> UserDTO {
        try await loadUser(id, includeProfile: includeProfile, on: request.db)
    }
}
```

Multiple response attributes can describe different status codes.

```swift
@OpenAPIResponse(.ok, body: UserDTO.self)
@OpenAPIResponse(.notFound, body: APIError.self)
@Get(":id")
func show(_ request: Request, @Path id: UUID) async throws -> UserDTO {
    // ...
}
```

`OpenAPIResponse` acts as an override. Omit `body` to keep the inferred handler
return type while changing the status or description, or omit the status to
replace only the body type:

```swift
@OpenAPIResponse(.created)
@Post
func create(_ request: Request) async throws -> UserDTO {
    // ...
}

@OpenAPIResponse(body: PublicUserDTO.self)
@Get(":id")
func show(_ request: Request, @Path id: UUID) async throws -> InternalUserDTO {
    // ...
}
```

If no explicit response is provided, VaporKit uses the handler's return type
as the schema for a `200` response. The return type must conform to
``OpenAPISchema``; otherwise Swift reports a compile-time error.

For closure routes such as `#Get`, write an explicit closure return type so the
macro can infer the schema:

```swift
#Get("health") { _ -> HealthStatus in
    HealthStatus(ready: true)
}
```

When a closure omits its return type, or a handler returns an opaque type such
as `some AsyncResponseEncodable`, VaporKit emits a warning asking for an
explicit return type or ``OpenAPIResponse(_:body:description:)``.

When ``OpenAPIResponse(_:body:description:)`` is present but neither it nor the
handler provides an inferable body type, VaporKit uses `Never` as the response
body type. This means that no legal body value exists, so the generated response
omits `content`; it is distinct from optional metadata whose value is `nil`.

## Describe Request Bodies

A typed handler with one ``ContentBody`` parameter automatically emits an
OpenAPI request body. A non-optional parameter without a default is required;
an optional or defaulted parameter produces an optional request body.

```swift
@Post
func create(
    _ request: Request,
    @ContentBody body: CreateUserRequest
) async throws -> UserDTO {
    // ...
}
```

Closure routes cannot expose their decoded body type through their signature.
Use ``OpenAPIRequest(body:contentType:required:)`` to provide it explicitly:

```swift
@OpenAPIRequest(body: CreateUserRequest.self)
#Post("users") { request -> UserDTO in
    let body = try request.content.decode(CreateUserRequest.self)
    // ...
}
```

The same attribute overrides an inferred request schema, media type, or
required flag. If a typed handler declares multiple ``ContentBody`` parameters,
VaporKit emits a warning and requires this override to select the request body
represented in OpenAPI.

## Include Registered Routers

Child routers declared with ``Register(_:)`` are included in the exported
document with their complete paths.

```swift
@Router("api")
struct RootRouter {
    #Register(V1Router(), AdminRouter())
}

@Router("v1")
struct V1Router {
    #Register(UserRoutes())
}

@Router("admin")
struct AdminRouter {
    #Register(UserRoutes())
}
```

If `UserRoutes` has local path `"users"`, its handlers appear below both
`/api/v1/users` and `/api/admin/users`.

## Exclude Internal APIs

Attach ``OpenAPIIgnored()`` to a router or individual handler that should not
be exported.

```swift
@OpenAPIIgnored
@Get("internal")
func internalStatus(_ request: Request) async throws -> String {
    request.url.path
}
```

Ignoring OpenAPI metadata does not change Vapor route registration.

## Topics

### Operation Metadata

- ``OpenAPI(operationID:summary:description:tags:)``
- ``OpenAPIRequest(body:contentType:required:)``
- ``OpenAPIResponse(_:body:description:)``
- ``OpenAPIIgnored()``

### Schema

- ``OpenAPISchema()``
- ``OpenAPISchema``
