# Migrating Code From Vapor-style Routing

This article shows how to migrate existing Vapor route collections to
VaporKit.

## Marking Code by Macros

To get started, import VaporKit.

Finds the `RouteCollection` you want to migrate, and add ``Router(_:)``
to it.

@Row {
    @Column {
        ```swift
        // Legacy
        
        struct Controller: RouteCollection
        ```
    }
    @Column {
        ```swift
        // VaporKit
        @Router
        struct Controller
        ```
    }
}

For all the handler functions, mark it with 
``RouteHandler(_:method:)-xbrl``.
Then based on its HTTP method, add method information.

@Row {
    @Column {
        ```swift
            // Legacy
            
            // routes.get("name", use: getName)
            func getName(req: Request) async throws -> String
        ```
    }
    @Column {
        ```swift
            // VaporKit
            
            @RouteHandler("name", method: .GET)
            func getName(req: Request) async throws -> String
        ```
    }
}

## Adopting Routes

Now, focusing on `routes()` in legacy code.

- Find common routes, like

  ```swift
  routes.group("route") { ... }
  ```

  or

  ```swift
  routes.grouped("route")
  ```

  Add common route to `@Router`.

  ```swift
  @Router("route")
  ```

- For every register function like `on(_:use:)`, `get(_:use:)`,  
  `post(_:use:)`, add routes to their `@RouteHandler`.

  ```swift
  @RouteHandler("name", ":id", method: .GET) // or "name/:id"
  ```

@Row {
    @Column {
        ```swift
        // Legacy
        
        struct Controller: RouteCollection {
            func boot(routes: any Vapor.RoutesBuilder) throws {
                let grouped = routes.grouped("route")
                grouped.get("name", ":id", use: getName)
            }
            
            func getName(req: Request) async throws -> String {
                // ...
            }
        }
        ```
    }
    @Column {
        ```swift
        // VaporKit
        
        @Router("route")
        struct Controller {
            @RouteHandler("name/:id", method: .GET)
            func getName(req: Request) async throws -> String {
                // ...
            }
        }
        ```
    }
}

## Migrating Socket

Replace `routes.webSocket` to `#WebSocket`, and put it into structure 
body.

Removing closure parameter in `didUpgrade`, and replace `ws.onText` to 
`#OnText`, `ws.onBinary` to `#OnBinary`, `ws.onClose` to `#OnClose`.

@Row {
    @Column {
        ```swift
        // Legacy
        
        struct Controller: RouteCollection {
            func boot(routes: any Vapor.RoutesBuilder) throws {
                routes.webSocket("some", "route", maxFrameSize: .default) { request in
                    // shouldUpgrade
                } didUpgrade: { req, ws in
                    ws.onText { ws, string in 
                        // ...
                    }
                    
                    ws.onBinary { ws, data in 
                        // ...
                    }
                    
                    ws.onClose {
                        // ...
                    }
                }
            }
        }
        ```
    }
    @Column {
        ```swift
        // VaporKit
        
        @Router
        struct Controller {
            #WebSocket("some", "route", maxFrameSize: .default) { req in
                // shouldUpgrade
            } didUpgrade: {
                #OnText { ws, string in
                    // ...
                }
            
                #OnBinary { ws, data in
                    // ...
                }
                
                #OnClose {
                    // ...
                }
            }
        }
        ```
    }
}

## Manually Define Forward Parameters

If you are migrating an child controller, defining parameter symbol is
very important for Automatic Compile-time Parameter Checking System,
find out more in <doc:CreateRouter#Find-Errors-at-Compile-time>.

For instance, a super controller define symbol `name` and `id`.

```swift
@Router
struct ChildrenController {
    #ForwardParameters("name", "id")
    // ...
}
```

## Finally, Remove routes()

After every steps done, remove legacy `routes()` from your declaration,
rebuild project, nothing further needs to be aware, then you can see 
changes.

## Topics

### Mark a Written Handler Function

- ``RouteHandler(_:method:)-xbrl``
- ``RouteHandler(_:method:)-9lbrn``

## See Also

- <doc:CreateRouter>
