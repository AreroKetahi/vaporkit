# VaporKit

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAreroKetahi%2Fvaporkit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/AreroKetahi/vaporkit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAreroKetahi%2Fvaporkit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/AreroKetahi/vaporkit)

VaporKit is a Swift macro package for reducing repetitive Vapor routing and
validation code while keeping the generated code close to Vapor's native APIs.

It focuses on four workflows:

- Declaring a Vapor application entry point and startup manifest.
- Building `RouteCollection` implementations with route declaration macros.
- Building `Validatable` models with property-level validation constraints.
- Exporting linked router metadata as an OpenAPI 3.1 document (Alpha).

## Requirements

- Swift 6.3 or newer
- Vapor 4.121.0 or newer
- macOS 14 or newer, or Linux

## Installation

Add VaporKit to your package dependencies.

```swift
dependencies: [
    .package(url: "https://github.com/AreroKetahi/vaporkit.git", branch: "main")
]
```

Then add the library product to your target.

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "VaporKit", package: "vaporkit")
    ]
)
```

Import it where you define routes or validation models.

```swift
import Vapor
import VaporKit
```

## Routing

VaporKit supports two routing declaration styles:

- **Convenient routing declarations** use compact route closures.
- **Parameterized routing declarations** use regular functions with typed
  parameters in the signature.

### Convenient Routing Declarations

Attach `@Router` to a type to synthesize `RouteCollection` conformance and a
`boot(routes:)` implementation.

```swift
@Router("api/users")
struct UserRoutes {
    #Get(":id") { req in
        let id = try req.parameters.require("id", as: UUID.self)
        return "User \(id)"
    }

    #Post { req -> HTTPStatus in
        let user = try req.content.decode(CreateUserRequest.self)
        try await createUser(user, on: req.db)
        return .created
    }
}
```

Use this style for short handlers that are easiest to read inline. The closure
can use any request parameter name, or shorthand `$0`.

#### HTTP Helpers

VaporKit provides method-specific helpers:

- `#Get`
- `#Post`
- `#Put`
- `#Delete`

Use `#On` when you need to provide the method explicitly.

```swift
#On("trace/:id", method: .TRACE) { req in
    try req.parameters.require("id")
}
```

#### Existing Handler Functions

Use `@RouteHandler` when you want to keep a named function and register it from
the generated `boot(routes:)`.

```swift
@Router("api")
struct AdminRoutes {
    @RouteHandler("health", method: .GET)
    func health(req: Request) -> HTTPStatus {
        .ok
    }
}
```

#### Middleware

Attach `@Middleware` to a route declaration or route handler function.

```swift
@Middleware(AuthMiddleware(), RateLimitMiddleware())
#Get("profile") { req in
    req.url.path
}
```

The generated route is registered on `routes.grouped(...)`.

#### Child Route Collections

Use `#Register` to register one or more child `RouteCollection` values below
the enclosing router prefix.

```swift
@Router("api/:tenantID")
struct APIRoutes {
    #Register(UserRoutes(), AdminRoutes())
}
```

### Parameterized Routing Declarations

Use this style when a handler has named inputs or is clearer as a regular
function. The first parameter is `Request`; additional values are declared with
`@Path`, `@Query`, `@ContentBody`, or `@Auth`.

```swift
@OpenAPISchema
struct SearchQuery: Codable {
    var term: String
    var limit: Int
}

@OpenAPISchema
struct UpdateUserRequest: Content {
    var username: String
}

@Router("api/users")
struct UserRoutes {
    @Get(":id")
    func show(
        req: Request,
        @Path id: UUID,
        @Query("include.profile") includeProfile: Bool = false
    ) async throws -> UserDTO {
        try await loadUser(id, includeProfile: includeProfile, on: req.db)
    }

    @Get("search")
    func search(
        req: Request,
        @Query input: SearchQuery,
        @Query("filter.name") name: String?,
        @Query("page/number") page: Int = 1
    ) async throws -> [UserDTO] {
        try await searchUsers(input, name: name, page: page, on: req.db)
    }

    @Put(":id")
    func update(
        req: Request,
        @Path id: UUID,
        @ContentBody body: UpdateUserRequest
    ) async throws -> UserDTO {
        try await updateUser(id, with: body, on: req.db)
    }

    @Get("profile")
    func profile(req: Request, @Auth user: User) async throws -> UserDTO {
        try await loadProfile(for: user, on: req.db)
    }
}
```

Use `@Path` for route parameters, `@Query` for query values, and
`@ContentBody` for request bodies. Use `@Auth` for values loaded from
`Request.auth`. `@Query`, `@ContentBody`, and `@Auth` support optional types
and default values.

Typed paths can also select path-parameter parsing with `RouterPath`
interpolation. The path defines the label and parsing strategy, while `@Path`
independently injects the captured value into the function:

```swift
@Get("users/\("id", decoding: UUID.self)")
func find(req: Request, @Path id: UUID) async throws -> UserDTO {
    try await loadUser(id, on: req.db)
}

@Get("pages/\("page", converting: Int.self)")
func page(req: Request, @Path page: Int) -> String {
    String(page)
}

@Get("articles/\(key: "slug")")
func article(req: Request, @Path slug: String) -> String {
    slug
}
```

`key:` retains the existing conversion behavior, `decoding:` uses URL-encoded
`Decodable` parsing, and `converting:` uses `LosslessStringConvertible`.
Traditional paths such as `"users/:id"` remain supported. Interpolated names
must be static, non-empty string literals without `/` or `:`.

## Application Entry Point

Define application setup as a `VaporAppConfiguration` value:

```swift
struct ServerConfiguration: VaporAppConfiguration {
    func configure(_ application: Application) async throws {
        application.middleware.use(FileMiddleware(
            publicDirectory: application.directory.publicDirectory
        ))
        try routes(application)
    }
}
```

Declare the executable entry point with `VaporApplication`:

```swift
@main
struct MyServer: VaporApplication {
    static let commandName = "my-server"
    static let abstract = "Runs the MyServer API."
    static let version = "1.0.0"

    static let manifest = VaporAppManifest(
        configurations: [ServerConfiguration()]
    )
}
```

Use `commandName`, `abstract`, `discussion`, and `version` to customize the
Argument Parser root command. Each property has a default value and can be
omitted.

When every router uses `@AutoRegisterable`, use the built-in configuration:

```swift
@main
struct MyServer: VaporApplication {
    static let manifest = VaporAppManifest(
        configurations: [AutoRegisterRoutesConfiguration.default]
    )
}
```

Continue passing Vapor and ConsoleKit arguments normally:

```bash
swift run MyServer --env production serve \
  --hostname 0.0.0.0 \
  --port 8080
```

VaporKit uses Argument Parser for the static application command hierarchy and
passes server arguments through to Vapor's ConsoleKit parser. Configuration
values are fixed by the static manifest and run in declaration order before the
application lifecycle begins.

Use `VaporAppLifecycleHandler` only for resources that belong to the running
application. A configuration that throws remains responsible for cleaning up
its own incomplete work.

For migration instructions, lifecycle handlers, and custom application
commands, see the documentation.

## OpenAPI Export (Alpha)

> [!WARNING]
> OpenAPI export is currently an Alpha feature. Its generated document shape,
> schema inference rules, and public APIs may change before stabilization.

VaporKit can export OpenAPI metadata without starting a Vapor application or
registering a ConsoleKit command. The router declarations only need to be
linked into the server executable.

Annotate response models with `@OpenAPISchema`. Every stored property type must
also conform to `OpenAPISchema`, so unsupported nested schema types fail during
compilation.

```swift
@OpenAPISchema
struct UserDTO: Content {
    var id: UUID
    var name: String
    var nickname: String?
}

@Router("api/users")
struct UserRoutes {
    @OpenAPI(
        summary: "Get a user",
        tags: ["Users"]
    )
    @OpenAPIResponse(.ok, body: UserDTO.self)
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

Make the server entry point conform to `VaporApplication`, then run its
`extract-openapi` subcommand:

```swift
@main
struct MyServer: VaporApplication {
    static let manifest = VaporAppManifest()
}
```

```bash
./.build/release/MyServer extract-openapi \
  --title "Users API" \
  --version "1.0.0" \
  --output openapi.json
```

The command discovers metadata inside the server process without creating or
starting a Vapor `Application`.

Child routers declared with `#Register` are included with their full paths. Use
`@OpenAPIIgnored` on a router or handler that should not appear in the document.
Typed `@Path`, `@Query`, and `@ContentBody` types must conform to
`OpenAPISchema`; a single `@ContentBody` automatically becomes the operation's
request body. Use `@OpenAPIRequest(body:)` to describe a closure route body or
override the inferred request metadata.
When `@OpenAPIResponse` is omitted, the handler's explicit return type becomes
the schema for a `200` response and must conform to `OpenAPISchema`. Closure
routes without an explicit return type produce a warning.
Use `@OpenAPIResponse(.created)` to override only the status, or
`@OpenAPIResponse(body: PublicDTO.self)` to override only the body schema.
If an explicit `@OpenAPIResponse` still has no inferable body type, VaporKit
uses `Never` to represent that the response has no legal body value and omits
the OpenAPI `content` field.

For the complete setup and inference rules, see
[`Export OpenAPI`](Sources/VaporKit/Documentation.docc/ExportOpenAPI.md).

## WebSocket Routes

Use `#WebSocket` inside a router and declare events with `#OnText`, `#OnBinary`,
and `#OnClose`.

```swift
@Router("api")
struct SocketRoutes {
    #WebSocket("chat") { req in
        ["X-Request-ID": req.id.uuidString]
    } didUpgrade: {
        #OnText {
            await $0.send($1)
        }

        #OnBinary { ws, buffer in
            await ws.send(buffer)
        }

        #OnClose {
            print("closed")
        }
    }
}
```

`#OnText` and `#OnBinary` support either explicit parameters or `$0` / `$1`.
When shorthand is used, VaporKit rewrites those references to generated unique
names to avoid collisions with user code.

## Route Parameter Checking

VaporKit performs syntax-only checks for direct route parameter access:

```swift
req.parameters.get("id")
try req.parameters.require("id")
```

If a handler reads a parameter that is not declared in the route path, the macro
emits a diagnostic.

```swift
#Get("users/:id") { req in
    try req.parameters.require("slug") // compile-time diagnostic
}
```

When a child router receives parameters from a parent router, declare those
names with `#ForwardParameters`.

```swift
@Router("users")
struct UserRoutes {
    #ForwardParameters("tenantID")

    #Get(":id") { req in
        let tenantID = try req.parameters.require("tenantID")
        let id = try req.parameters.require("id")
        return "\(tenantID)/\(id)"
    }
}
```

Use `@DisableParameterCheck` to opt out at the router or route level.

```swift
@DisableParameterCheck
@Router("legacy")
struct LegacyRoutes {
    #Get("dynamic") { req in
        try req.parameters.require("runtimeOnly")
    }
}
```

Use `#Bypass` when one expression or local code block should be skipped.

```swift
let value = #Bypass {
    let fallback = try req.parameters.require("id")
    return req.parameters.get(dynamicName) ?? fallback
}
```

The checker is intentionally syntax-only. It does not resolve aliases, type
information, or every possible expression form.

## Validation

Attach `@ValidatableModel` to a model and describe property validations with
`@Constraint`.

```swift
@ValidatableModel
struct CreateUserRequest: Content {
    @Constraint(.alphanumeric && .count(3...32))
    var username: String

    @Constraint(.email)
    var email: String

    @Constraint(.count(8...), message: "Password is too short.")
    var password: String
}
```

VaporKit generates the `Validatable` conformance and `validations(_:)`
implementation.

### Validation Rules

`ValidationRule` supports common Vapor validators:

- `.ascii`
- `.alphanumeric`
- `.email`
- `.empty`
- `.url`
- `.nil`
- `.characterSet(...)`
- `.count(...)`
- `.range(...)`
- `.in(...)`

Rules can be composed with `!`, `&&`, and `||`.

```swift
@Constraint(.email || .empty)
var recoveryEmail: String
```

### Custom Constraints

Use the custom constraint overload for predicates that cannot be expressed by
built-in validators.

```swift
@Constraint(validating: String.self, message: "Name is reserved.") { name in
    !["admin", "root", "system"].contains(name.lowercased())
}
var username: String
```

## Documentation

The DocC catalog includes task-oriented guides:

- `Create Router`
- `Migrating Code From Vapor-style Routing`
- `Build a Validation System`
- `Migrating From Vapor Validation`

Generate documentation with Swift Package Manager or view it in Xcode's
documentation browser.

## Testing

Run the test suite with:

```bash
swift test
```

In constrained environments, it can be useful to redirect Swift and Clang module
caches:

```bash
env CLANG_MODULE_CACHE_PATH=/tmp/clang-module-cache \
    SWIFTPM_MODULECACHE_OVERRIDE=/tmp/swiftpm-module-cache \
    swift test
```
