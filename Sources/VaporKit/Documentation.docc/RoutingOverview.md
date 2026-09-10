# Routing

Declare Vapor routes with compile-time generated code and optional runtime discovery.

## Overview

VaporKit offers two levels of route declaration. Freestanding route macros such
as `#Get` are the shortest path for inline handlers. Attached route macros such
as `@Get` provide the complete routing model, including parameter injection,
middleware, OpenAPI metadata, and WebSocket callbacks.

Group either style in a type annotated with ``Router(_:)``. The macro generates
an ordinary Vapor `RouteCollection`, so routing itself adds no runtime layer.

### Routers

Use ``Router(_:)`` to give a route collection a shared path. Compose larger
route trees with ``Register(_:)`` and apply shared middleware with
``Middleware(_:)``.

```swift
@Router("api")
struct APIRouter {
    #Register(UserRoutes(), HealthRoutes())
}

@Router("users")
struct UserRoutes {
    @Middleware(UserAuthenticator())
    #Get("me") { request in
        try request.auth.require(User.self)
    }
}
```

### Freestanding Route Macros

Use `#Get`, `#Post`, `#Put`, `#Delete`, or `#On` when the complete handler fits
comfortably in a closure. These macros keep simple endpoints compact while
still generating native Vapor registration code.

```swift
@Router("health")
struct HealthRoutes {
    #Get { _ in HTTPStatus.ok }
    #On("ready", method: .HEAD) { _ in HTTPStatus.ok }
}
```

### Full-Featured Routes

Use the attached forms `@Get`, `@Post`, `@Put`, `@Delete`, and `@On` on methods
when a route needs injected path, query, body, cookie, header, or authentication
values. The same form supports static parameter checks and OpenAPI annotations.

```swift
@Put(":id")
func update(
    request: Request,
    @Path id: UUID,
    @Query("notify") notify: Bool = false,
    @ContentBody body: UpdateUserRequest,
    @Auth actor: User
) async throws -> UserDTO {
    try await updateUser(id, with: body, by: actor, notify: notify, on: request.db)
}
```

### Automatic Registration

Add ``AutoRegisterable()`` to discover a router at runtime, then register all
discovered routers with `Application.autoRegisterRouters()` or
``AutoRegisterRoutesConfiguration``. This capability is opt-in; routers can
always be registered explicitly through Vapor.

```swift
@AutoRegisterable
@Router("health")
struct HealthRoutes {
    #Get { _ in HTTPStatus.ok }
}

func configure(_ application: Application) throws {
    try application.autoRegisterRouters()
}
```

### Migrating from Vapor Routing

Start with <doc:MigratingFromVaporRouting> to translate an existing
`RouteCollection` incrementally while preserving Vapor's routing behavior.

### WebSocket Routes

Declare a WebSocket upgrade inside a router and add callbacks in its upgrade
body:

```swift
@Router("chat")
struct ChatRoutes {
    #WebSocket(":room") { request in
        guard request.headers.bearerAuthorization != nil else {
            return nil
        }
        return ["X-Room": try request.parameters.require("room")]
    } didUpgrade: {
        #OnText { socket, message in
            socket.send(message)
        }

        #OnBinary { socket, bytes in
            socket.send(raw: bytes, opcode: .binary)
        }

        #OnClose {
            // Release connection-specific resources.
        }
    }
}
```

## Topics

### Defining Routers

- ``Router(_:)``
- ``RouterPath``
- ``Register(_:)``
- ``Middleware(_:)``

### Freestanding Route Macros

- ``Get(_:action:)``
- ``Post(_:action:)``
- ``Put(_:action:)``
- ``Delete(_:action:)``
- ``On(_:method:action:)``

### Full-Featured Route Macros

- ``Get(_:)``
- ``Post(_:)``
- ``Put(_:)``
- ``Delete(_:)``
- ``On(_:method:)``
- ``RouteHandler(_:method:)-xbrl``
- ``RouteHandler(_:method:)-(RouterPath?,_)``

### Route Parameters

- ``Path``
- ``Query``
- ``ContentBody``
- ``Cookie``
- ``Header``
- ``Auth``

### Static Checking

- ``ForwardParameters(_:)``
- ``DisableParameterCheck(as:)``
- ``Bypass(as:_:)``
- ``StaticCheckSeverity``

### Automatic Registration

- ``AutoRegisterable()``
- ``AutoRegisterRoutesConfiguration``

### WebSocket Routes

- ``WebSocket(_:maxFrameSize:shouldUpgrade:didUpgrade:)``
- ``OnText(action:)``
- ``OnBinary(action:)``
- ``OnClose(action:)``

### Articles

- <doc:CreateRouter>
- <doc:UsingParameterInFunction>
- <doc:RouterInjection>
- <doc:StaticRouteParameterChecking>
- <doc:MigratingFromVaporRouting>
