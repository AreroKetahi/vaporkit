# VaporKit

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAreroKetahi%2Fvaporkit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/AreroKetahi/vaporkit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAreroKetahi%2Fvaporkit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/AreroKetahi/vaporkit)

VaporKit is a Swift macro package for reducing repetitive Vapor routing and
validation code while keeping the generated code close to Vapor's native APIs.

It focuses on two workflows:

- Building `RouteCollection` implementations with route declaration macros.
- Building `Validatable` models with property-level validation constraints.

## Requirements

- Swift 6.3 or newer
- Vapor 4.121.0 or newer
- macOS, iOS, tvOS, watchOS, or Mac Catalyst targets supported by the package

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
`@Path`, `@Query`, or `@ContentBody`.

```swift
struct SearchQuery: Decodable {
    var term: String
    var limit: Int
}

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
}
```

Use `@Path` for route parameters, `@Query` for query values, and
`@ContentBody` for request bodies. `@Query` and `@ContentBody` support optional
types and default values.

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
