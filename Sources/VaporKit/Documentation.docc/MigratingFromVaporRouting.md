# Migrating from Vapor Routing

Move an existing `RouteCollection` to VaporKit without changing route behavior.

## Overview

Migrate one collection at a time. Replace its conformance and `boot(routes:)`
registration with ``Router(_:)`` and route annotations; callers can continue to
register the resulting type as a normal Vapor `RouteCollection`.

@Row {
    @Column {
        ```swift
        // Vapor
        struct UserController: RouteCollection {
            nonisolated(nonsending) func boot(routes: any RoutesBuilder) async throws {
                let users = routes.grouped("users")
                users.get(":id", use: show)
            }

            func show(request: Request) async throws -> UserDTO {
                let id = try request.parameters.require("id", as: UUID.self)
                return try await loadUser(id, on: request.db)
            }
        }
        ```
    }
    @Column {
        ```swift
        // VaporKit
        @Router("users")
        struct UserController {
            @Get(":id")
            func show(request: Request, @Path id: UUID) async throws -> UserDTO {
                try await loadUser(id, on: request.db)
            }
        }
        ```
    }
}

### Translate Registrations

| Vapor                          | VaporKit                                                |
| ------------------------------ | ------------------------------------------------------- |
| `routes.grouped("users")`      | `@Router("users")`                                      |
| `routes.get(..., use:)`        | `@Get` or `#Get`                                        |
| `routes.on(method, ..., use:)` | ``On(_:method:)`` or ``On(_:method:action:)``           |
| `routes.grouped(middleware)`   | ``Middleware(_:)``                                      |
| `routes.register(collection:)` | ``Register(_:)``                                        |

WebSocket migration is only available on the Vapor 4 release line. The current
Vapor 5 beta dependency does not support VaporKit's WebSocket macros.

Use ``RouteHandler(_:method:)-(RouterPath?,_)`` when preserving an existing handler name
is clearer than selecting a method-specific macro. See <doc:CreateRouter> for
choosing between closure and method handlers.

### Preserve Parent Parameters

If a child collection reads path parameters declared by its parent, add
``ForwardParameters(_:)`` to the child. The reason and severity controls are
described in <doc:StaticRouteParameterChecking>.

After all registrations have moved to annotations, remove `boot(routes:)` and
rebuild. Keep explicit Vapor registration for routers that require constructor
dependencies; automatic registration is optional.

## Topics

### Migration APIs

- ``Router(_:)``
- ``RouteHandler(_:method:)-(RouterPath?,_)``
- ``ForwardParameters(_:)``
