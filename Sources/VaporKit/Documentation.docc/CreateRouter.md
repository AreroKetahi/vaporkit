# Create Router

Create Vapor `RouteCollection` in few macros.

## Overview

Traditionally, creates a `RouteCollection` need to handwriting a large 
mass of codes. This takes a lot of mental affort to maintain controller
register codes.

But now with a collection of macros, all maintainance work will be 
finish by macros! The only things you need to do is writing logic.

## Create a Router

To avoid symbol conflicts, VaporKit use ``Router(_:)`` to create a new
controller. You definitly can add this macro in structure or class, 
however structure is recommended.

```swift
@Router
struct LoginController {
    // handler here...
}
```

### Create Route Handler

Define route handler is as breath as easy, use ``Get(_:action:)``, 
``Post(_:action:)``, ``Put(_:action:)``, or ``Delete(_:action:)`` to
create a RESTful API. or use ``On(_:method:action:)`` to select a 
customise HTTP method.

You can create a `GET` method like this:

```swift
#Get { req in
    return "You're logged in!"
}
```

Or a `POST` method like this:

```swift
#Post(":id") {
    let id = try $0.parameters.get("id")
    return "Hello, \(id)!"
}
```

Or you want to `TRACE` something:

```swift
#On(.TRACE, ":item") { request -> HTTPStatus in
    if try TraceResult(of: request.parameters.get("item") == .ok {
        return .ok
    } else {
        return .notFound
    }
}
```

You might noticed, this cases above use `req`, `request`, `$0` as the
Request identifier, and that is **completely acceptable**.

> Tip:
> You can use any closure identifer as you want in handler declaration,
> even `$0`, and result type is optional also.

### Customize Routing

``Router(_:)`` accepts a string literal, that define root route in
whole controller.

```swift
@Route("update") // all routes start with /update
```

For ``Get(_:action:)`` and its relative, accepts a string that 
fine-tuning route.

```swift
#Get("brief") { // In this case, route is /update/brief
    // ...
}
```

If you want to mark a route node as a parameter, samely add "`:`" 
before node. Like "update/:id".

You can also remain a "`/`" before route, e.g. `"/update"` is acceptable
also.

## Install Middleware

Attach ``Middleware(_:)`` to your declaration can instant setup a 
middleware during the request.

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

Use ``Register(_:)``, and one or more children controllers can be 
register under a centain controller.

```swift
@Router("staff")
struct StaffController {
    #Register(StaffGroupController(), StaffChatController())
    // ...
}
```

## Supporting WebSocket

There is server macro helps you define a WebSocket handler.

By adding a WebSocket Hanlder, use 
``WebSocket(_:maxFrameSize:shouldUpgrade:didUpgrade:)`` directly in
router.

```swift
@Router
struct SocketRouter {
    #WebSocket {
        // ...
    }
}
```

Like Vapor API, you can customise the behaviour before upgrade.

```swift
@Router
struct SocketRouter {
    #WebSocket(maxFrameSize: .default) { req in // or event set frame size
        // ...
    } didUpgrade: {
        // ...
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

Samely, identifiers' name are insensitive.

## Find Errors at Compile-time

VaporKit allows compiler find some code error in compile time. Like
route parameter coverage.

While you write `<request>.parameters.get("identifier")`, VaporKit will 
scan whole syntax tree to find if this identifier is defined. If you 
referenced a undefined identifier, a compile error will appears to warn 
you.

```swift
#Get(":name") { req in
    return try req.parameters.get("id") // This must be an error!!!
}
```

Additionally, use ``ForwardParameters(_:)`` allows you explictly state
super controller's parameters.

```swift
#ForwardParameters("who", "when", "where")
```

You can also use ``DisableParameterCheck()`` to silent parameter check.

```swift
@Router @DisableParameterCheck // Silence whole router
struct SayHello {
    @DisableParameterCheck // Silence only this one
    #Get(":name") { req in
        let name = try req.parameters.get("id")
        return "Hello \(name)!"
    }
}
```

If you want to silence parameter check more concisly, use 
``Bypass(_:)``.

```swift
// This call will NEVER be an error.
#Bypass { try req.parameters.get("id") }
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
- ``DisableParameterCheck()``
- ``Bypass(_:)``

## See Also

- <doc:MigratingFromVaporRouting>
