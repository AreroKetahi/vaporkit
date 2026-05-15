# VaporKit

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
    .package(url: "https://github.com/AreroKetahi/vaporkit.git", from: "0.1.0")
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
        try await user.save(on: req.db)
        return .created
    }
}
```

The route closure can use any request parameter name, or shorthand `$0`.
Explicit return types are preserved, so declarations such as
`{ req -> HTTPStatus in ... }` generate a handler returning `HTTPStatus`.

### HTTP Helpers

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

### Existing Handler Functions

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

### Middleware

Attach `@Middleware` to a route declaration or route handler function.

```swift
@Middleware(AuthMiddleware(), RateLimitMiddleware())
#Get("profile") { req in
    req.url.path
}
```

The generated route is registered on `routes.grouped(...)`.

### Child Route Collections

Use `#Register` to register one or more child `RouteCollection` values below
the enclosing router prefix.

```swift
@Router("api/:tenantID")
struct APIRoutes {
    #Register(UserRoutes(), AdminRoutes())
}
```

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

Use `#Bypass` when only one expression should be skipped.

```swift
let value = #Bypass {
    try req.parameters.require(dynamicName)
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
