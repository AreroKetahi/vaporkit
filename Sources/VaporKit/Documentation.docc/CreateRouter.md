# Creating a Router

Define and register a route collection with VaporKit macros.

## Overview

Annotate a type with ``Router(_:)``, then add routes to its body:

```swift
@Router("users")
struct UserRoutes {
    #Get { _ in
        "All users"
    }

    #Get(":id") { request in
        try request.parameters.require("id", as: UUID.self)
    }
}
```

The router becomes an ordinary Vapor `RouteCollection`. Register it explicitly
when it has dependencies:

```swift
try application.register(collection: UserRoutes())
```

For dependency-free routers, opt in to runtime discovery with
``AutoRegisterable()`` and call
`Application.autoRegisterRouters()` during configuration.

Add ``Middleware(_:)`` to a route or compose child collections with
``Register(_:)``. See <doc:RoutingOverview> for the complete routing API.

### Choose a Handler Style

Use freestanding macros such as `#Get` for compact closures. Use attached
macros such as `@Get` for method-based handlers with injected request values:

```swift
@Get(":id")
func find(request: Request, @Path id: UUID) async throws -> UserDTO {
    try await loadUser(id, on: request.db)
}
```

For all supported parameter sources, see <doc:UsingParameterInFunction>. For
compile-time path diagnostics, see <doc:StaticRouteParameterChecking>.

## See Also

- <doc:UsingParameterInFunction>
- <doc:MigratingFromVaporRouting>
