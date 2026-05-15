# Create Router

Create a Vapor `RouteCollection` with a few macros.

## Overview

Traditional `RouteCollection` implementations often mix route registration
with handler logic. As a controller grows, maintaining that registration code
can become repetitive and error-prone.

VaporKit moves route registration into macros so the router declaration stays
close to the handler code.

## Create a Router

Attach ``Router(_:)`` to a struct or class to create a route collection.
Structs are recommended for most route groups.

```swift
@Router
struct LoginController {
    // handler here...
}
```

### Create Route Handler

Use ``Get(_:action:)``, ``Post(_:action:)``, ``Put(_:action:)``, or
``Delete(_:action:)`` to create REST-style routes. Use
``On(_:method:action:)`` when you need to choose the HTTP method directly.

You can create a `GET` method like this:

```swift
#Get { req in
    return "You're logged in!"
}
```

Or a `POST` method like this:

```swift
#Post(":id") {
    let id = $0.parameters.get("id")
    return "Hello, \(id)!"
}
```

Or you want to `TRACE` something:

```swift
#On(":item", method: .TRACE) { request -> HTTPStatus in
    if try TraceResult(of: request.parameters.require("item")) == .ok {
        return .ok
    } else {
        return .notFound
    }
}
```

The examples above use `req`, `request`, and `$0` as the request identifier.
All of those forms are supported.

> Tip:
> You can use any closure identifier in handler declarations,
> even `$0`, and result type is optional also.

### Customize Routing

``Router(_:)`` accepts a string literal that defines the base path for the
whole controller.

```swift
@Router("update") // all routes start with /update
```

Route macros such as ``Get(_:action:)`` accept a string literal path relative
to the router base path.

```swift
#Get("brief") { // In this case, route is /update/brief
    // ...
}
```

Prefix a path segment with `:` to declare a route parameter, such as
`"update/:id"`.

Leading slashes are accepted, so `"/update"` and `"update"` are normalized the
same way.

## Install Middleware

Attach ``Middleware(_:)`` to a route declaration to register that route on a
middleware group.

```swift
@Middleware(CheckLoginStatus())
#Post { request in
    guard let result = try? await request.tracker.update() else {
        throw Abort(status: .notFound)
    }
    return result
}
```

You can add a lot of middlewares at once.

```swift
@Middleware(CheckLoginStatus(), RequestPermission(), CheckRegion())
#Post { request in
    // ...
}
```

## Registering Children Controllers

Use ``Register(_:)`` to register one or more child route collections under the
current router's base path.

```swift
@Router("staff")
struct StaffController {
    #Register(StaffGroupController(), StaffChatController())
    // ...
}
```

## Supporting WebSocket

VaporKit also provides macros for WebSocket routes.

Use ``WebSocket(_:maxFrameSize:shouldUpgrade:didUpgrade:)`` directly inside a
router to add a WebSocket handler.

```swift
@Router
struct SocketRouter {
    #WebSocket {
        // ...
    }
}
```

Like Vapor's API, you can customize behavior before the upgrade completes.

```swift
@Router
struct SocketRouter {
    #WebSocket(maxFrameSize: .default) { req in // or event set frame size
        // ...
    } didUpgrade: {
        // ...
    }
}
```

Then use ``OnText(action:)``, ``OnBinary(action:)``, 
``OnClose(action:)`` inside `#WebSocket` closure to add event handler.

```swift
#WebSocket {
    #OnText { socket, string in
        // ...
    }
    
    #OnBinary { socket, data in
        // ...
    }
    
    #OnClose {
        // ...
    }
}
```

Callback parameter names are flexible, and shorthand `$0` / `$1` is also
supported for text and binary handlers.

## Find Errors at Compile-time

VaporKit can catch some route parameter mistakes during macro expansion.

When you write `<request>.parameters.get("identifier")` or
`<request>.parameters.require("identifier")`, VaporKit checks whether that
literal parameter name is declared in the route path.

```swift
#Get(":name") { req in
    return try req.parameters.require("id") // compile-time diagnostic
}
```

Use ``ForwardParameters(_:)`` to explicitly state parameters inherited from a
parent router.

```swift
#ForwardParameters("who", "when", "where")
```

You can also use ``DisableParameterCheck(as:)`` to silence or downgrade
parameter checks.

```swift
@DisableParameterCheck // Silence whole router
@Router
struct SayHello {
    @DisableParameterCheck // Silence only this one
    #Get(":name") { req in
        let name = req.parameters.get("id")
        return "Hello \(name)!"
    }
}
```

If you want to silence one expression, use
``Bypass(as:_:)``.

```swift
// This call will NEVER be an error.
#Bypass { req.parameters.get("id") }
```

## Topics

### Create Router

- ``Router(_:)``

### Define Handler

- ``On(_:method:action:)``
- ``Get(_:action:)``
- ``Post(_:action:)``
- ``Put(_:action:)``
- ``Delete(_:action:)``

### Middleware and Register

- ``Middleware(_:)``
- ``Register(_:)``

### Support WebSocket

- ``WebSocket(_:maxFrameSize:shouldUpgrade:didUpgrade:)``
- ``OnText(action:)``
- ``OnBinary(action:)``
- ``OnClose(action:)``

### Automatic Compile-time Parameter Checking

- ``ForwardParameters(_:)``
- ``DisableParameterCheck(as:)``
- ``Bypass(as:_:)``

## See Also

- <doc:MigratingFromVaporRouting>
- <doc:StaticRouteParameterChecking>
