# VaporKit

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAreroKetahi%2Fvaporkit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/AreroKetahi/vaporkit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAreroKetahi%2Fvaporkit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/AreroKetahi/vaporkit)

VaporKit provides mostly zero-cost abstractions over Vapor. Its macros replace
repetitive routing, request extraction, and validation code with ordinary Vapor
code at compile time. Runtime features are opt-in, so you only pay for the
capabilities you use.

[Read the complete documentation on Swift Package Index.](https://swiftpackageindex.com/AreroKetahi/vaporkit/documentation)

## Requirements

- Swift 6.3 or newer
- Vapor 4.121.0 or newer
- macOS 14 or newer, or Linux

## Installation

Add VaporKit to your package:

```swift
dependencies: [
    .package(
        url: "https://github.com/AreroKetahi/vaporkit.git",
        branch: "main"
    )
]
```

Then add `VaporKit` to your target:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "VaporKit", package: "vaporkit")
    ]
)
```

## Routing

### Route Declarations

Declare a route collection with `@Router`. Full route declarations are regular
handler functions whose request values are injected through the signature:

```swift
import Vapor
import VaporKit

@Router("api/users")
struct UserRoutes {
    @Get(":id")
    func show(
        req: Request,
        @Path id: UUID,
        @Query("include.profile") includeProfile: Bool = false,
        @Cookie(converting: "page") page: Int?,
        @Header(key: "Accept") accept: [String]
    ) async throws -> UserDTO {
        try await findUser(
            id,
            includeProfile: includeProfile,
            page: page,
            acceptedTypes: accept,
            on: req.db
        )
    }

    @Post
    func create(
        req: Request,
        @ContentBody input: CreateUser,
        @Auth user: User
    ) async throws -> UserDTO {
        try await createUser(input, by: user, on: req.db)
    }
}
```

VaporKit supports `@Path`, `@Query`, `@ContentBody`, `@Cookie`,
`@Header`, and `@Auth` injection.

For short handlers, the convenient freestanding route macros keep the route
inline:

```swift
@Router("api")
struct UserRoutes {
    #Get("users/:id") { req in
        let id = try req.parameters.require("id", as: UUID.self)
        return try await findUser(id, on: req.db)
    }

    #Post("users") { req -> HTTPStatus in
        let input = try req.content.decode(CreateUser.self)
        try await createUser(input, on: req.db)
        return .created
    }
}
```

### OpenAPI Generation

Annotate schema types and VaporKit can generate an OpenAPI document directly
from the linked route declarations:

```swift
@OpenAPISchema
struct UserDTO: Content {
    var id: UUID
    var name: String
}

@Router("api/users")
struct DocumentedUserRoutes {
    @Get(":id")
    func show(req: Request, @Path id: UUID) async throws -> UserDTO {
        try await findUser(id, on: req.db)
    }
}
```

```bash
swift run Server extract-openapi \
    --title "User API" \
    --version "1.0.0" \
    --output openapi.json
```

### Automatic Registration

Mark routers with `@AutoRegisterable` and use the built-in application
configuration to discover and register them automatically:

```swift
@AutoRegisterable
@Router("health")
struct HealthRoutes {
    #Get { _ in HTTPStatus.ok }
}

@main
struct Server: VaporApplication {
    static let manifest = VaporAppManifest(
        configurations: [AutoRegisterRoutesConfiguration.default]
    )
}
```

### Optional Program Entry Point

Optionally adopt `VaporApplication` for an Argument Parser-powered executable
with explicit startup configuration and custom subcommands:

```swift
struct Migrate: AsyncParsableCommand {
    mutating func run() async throws {
        try await migrateDatabase()
    }
}

@main
struct Server: VaporApplication {
    static let manifest = VaporAppManifest(
        configurations: [AutoRegisterRoutesConfiguration.default]
    )

    static let subcommands: [any ParsableCommand.Type] = [Migrate.self]
}
```

Argument Parser selects the command before Vapor creates or configures an
application. Only the default `run` command enters the application startup
lifecycle. Custom commands and `extract-openapi` remain available even when
application startup cannot complete, and never execute that startup code unless
their own implementation explicitly requests it.

## Validation

Generate Vapor validations from property declarations:

```swift
@ValidatableModel
struct CreateUser: Content {
    @Constraint(.alphanumeric && .count(3...32))
    var username: String

    @Constraint(.email)
    var email: String

    @Constraint(.count(8...), message: "Password is too short.")
    var password: String
}
```

For WebSockets, static parameter checking, migration guides, and the complete
API reference, see the
[documentation](https://swiftpackageindex.com/AreroKetahi/vaporkit/documentation).
