# Using Parameters in Functions

Write route handlers as regular functions and let VaporKit inject typed path
and query parameters.

## Overview

Vapor's native route parameters are read from `Request.parameters`:

```swift
#Get("users/:id") { req in
    let id = try req.parameters.require("id", as: UUID.self)
    return try await findUser(req: req, id: id)
}
```

Typed handler functions keep the same Vapor route model but move path and query
parameters into the function signature. Attach an HTTP method macro to a
function and mark injected path parameters with ``Path``:

```swift
@Router("users")
struct UserRoutes {
    @Get(":id")
    func find(req: Request, @Path("id") id: UUID) async throws -> UserDTO {
        try await loadUser(req: req, id: id)
    }
}
```

During macro expansion, ``Router(_:)`` generates a private wrapper-like
handler. The generated function receives only the request, reads the path
parameter with Vapor's `parameters.require`, and calls your original function:

```swift
func <generated-find>(req: Vapor.Request) async throws -> UserDTO {
    let <generated-id> = try req.parameters.require("id", as: UUID.self)
    return try await find(req: req, id: <generated-id>)
}
```

The registered route is still ordinary Vapor code:

```swift
routes.on(.GET, "users", ":id", use: <generated-find>)
```

## Declaring a Typed Handler

A typed handler function must be declared inside a ``Router(_:)`` type and
marked with one of the attached route macros:

```swift
@Router("projects")
struct ProjectRoutes {
    @Get(":id")
    func show(req: Request, @Path("id") id: UUID) throws -> ProjectDTO {
        try loadProject(id, for: req)
    }
}
```

Use ``On(_:method:)`` when the route needs a method that does not have a
dedicated helper:

```swift
@On(":id/archive", method: .PATCH)
func archive(req: Request, @Path("id") id: UUID) async throws -> HTTPStatus {
    try await archiveProject(id, on: req.db)
    return .accepted
}
```

``Get(_:)``, ``Post(_:)``, ``Put(_:)``, and ``Delete(_:)`` use their matching
HTTP methods automatically.

## Request Parameter

The first parameter must be `Request` or `Vapor.Request`. Its external label is
preserved in the generated wrapper call:

```swift
@Get(":id")
func show(request: Request, @Path("id") id: UUID) -> String {
    "\(request.method.rawValue):\(id)"
}
```

Underscored request parameters are supported as well:

```swift
@Delete(":id")
func delete(_ req: Vapor.Request, @Path("id") id: UUID) throws -> HTTPStatus {
    try deleteProject(id, on: req.db)
    return .noContent
}
```

The generated route handler still receives only that request parameter, so it
matches Vapor's route handler registration API.

## Path Parameters

Every function parameter after the request parameter must be marked with
``Path``:

```swift
@Get(":tenantID/users/:id")
func show(
    req: Request,
    @Path("tenantID") tenantID: UUID,
    @Path("id") id: UUID
) async throws -> UserDTO {
    try await loadUser(tenantID: tenantID, id: id, on: req.db)
}
```

The string passed to ``Path`` is the route parameter name without the leading
colon. For a route segment `":id"`, write `@Path("id")`.

The name is optional. When it is omitted, VaporKit uses the wrapped parameter's
local name:

```swift
@Get("projects/:key")
func show(req: Request, @Path of key: UUID) async throws -> ProjectDTO {
    try await loadProject(key: key, on: req.db)
}

@Get("users/:name")
func show(req: Request, @Path name: String) -> String {
    name
}
```

Path parameter values must conform to `LosslessStringConvertible`, matching
Vapor's `Request.parameters.require(_:as:)` API. Standard types such as
`String`, `Int`, `Double`, and `Bool` are supported by the standard library.
Vapor also makes `UUID` usable as a route parameter type.

## Query Parameters

Use ``Query`` for values decoded from `Request.query`:

```swift
struct SearchQuery: Decodable {
    var term: String
    var limit: Int
}

@Get("search")
func search(req: Request, @Query input: SearchQuery) async throws -> [ProjectDTO] {
    try await searchProjects(input, on: req.db)
}
```

When no key is provided, the generated wrapper decodes the full query string:

```swift
let <generated-input> = try req.query.decode(SearchQuery.self)
```

Pass a key to decode one value with Vapor's query key-path API:

```swift
@Get("search")
func search(
    req: Request,
    @Query("filter.name") name: String,
    @Query("page/number") page: Int
) -> String {
    "\(name):\(page)"
}
```

Dots and slashes both split the key into path components. The generated wrapper
uses `req.query.get(_:at:)`:

```swift
let <generated-name> = try req.query.get(String.self, at: "filter", "name")
let <generated-page> = try req.query.get(Int.self, at: "page", "number")
```

## Static Parameter Checking

Typed path parameters participate in VaporKit's route parameter checks. If a
``Path`` name is not declared by the route URL, the macro emits a diagnostic:

```swift
@Get(":id")
func show(req: Request, @Path("slug") slug: String) -> String {
    slug
}
```

The route declares `id`, but the function asks for `slug`, so VaporKit reports
that the required path parameter is not declared in the route URL.

The same controls described in <doc:StaticRouteParameterChecking> apply:

```swift
#ForwardParameters("tenantID")

@Get(":id")
func show(
    req: Request,
    @Path("tenantID") tenantID: UUID,
    @Path("id") id: UUID
) -> String {
    "\(tenantID)/\(id)"
}
```

Use ``ForwardParameters(_:)`` when a child router receives parameters from a
parent route. Use ``DisableParameterCheck(as:)`` when a router or route needs
to opt out of these checks.

## Choosing a Handler Style

Use freestanding route declarations when the handler is small or when the
logic naturally belongs inline:

```swift
#Get("health") { _ in
    HTTPStatus.ok
}
```

Use typed handler functions when the route has named path parameters or when
the handler body is easier to read as a normal method:

```swift
@Get("users/:id")
func find(req: Request, @Path("id") id: UUID) async throws -> UserDTO {
    try await loadUser(id, on: req.db)
}
```

Both forms generate Vapor-native route registrations. Typed handlers only
remove the repetitive parameter extraction code.

## Topics

### Typed Route Handlers

- ``Path``
- ``Get(_:)``
- ``Post(_:)``
- ``Put(_:)``
- ``Delete(_:)``
- ``On(_:method:)``
