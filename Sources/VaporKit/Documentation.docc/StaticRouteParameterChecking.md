# Static Route Parameter Checking

Use VaporKit's syntax-only analysis to catch route parameter drift while code
is still compiling.

## Overview

Vapor route parameters are runtime values. A route such as `users/:id` only
creates the `id` parameter after Vapor matches an incoming request. Without
extra checks, a handler can accidentally read another name and fail later at
runtime.

VaporKit checks the route path and handler body during macro expansion. When a
handler reads a literal parameter name that is not declared by the route path,
the macro emits a diagnostic at the access site.

```swift
@Router("users")
struct UserRoutes {
    #Get(":id") { req in
        try req.parameters.require("slug")
    }
}
```

The route declares `id`, but the handler requires `slug`, so VaporKit reports
that the required path parameter is not declared in the route URL.

## What Is Checked

The checker recognizes direct access through the request identifier:

```swift
req.parameters.get("id")
req.parameters.get("id", as: UUID.self)

try req.parameters.require("id")
try req.parameters.require("id", as: UUID.self)
```

The request identifier can be whatever the route closure or handler function
uses:

```swift
#Get(":id") { request in
    try request.parameters.require("id")
}

#Get(":id") {
    try $0.parameters.require("id")
}
```

Nested direct calls are also checked:

```swift
#Get(":id") { req in
    return try render(req.parameters.require("slug"))
}
```

This still reports `slug` because the access remains a direct
`req.parameters.require(...)` call.

## Syntax-Only Boundaries

The check is intentionally syntax-only. It does not run Swift type checking,
resolve aliases, inspect helper functions, or infer whether another value is a
`Request`.

These forms are not treated as statically proven route-parameter access:

```swift
let parameters = req.parameters
try parameters.require("id")

let copiedRequest = req
try copiedRequest.parameters.require("id")

try readID(from: req)
```

Keeping the check syntax-only makes diagnostics predictable and keeps macro
expansion lightweight. It catches the common route drift error without trying
to become a full semantic analyzer.

## Dynamic Parameter Names

VaporKit warns when a route parameter name comes from a variable or expression:

```swift
#Get(":id") { req in
    let key = "id"
    return req.parameters.get(key)
}
```

The value might be correct at runtime, but the macro cannot prove it from
syntax alone. Prefer a string literal when the name is fixed:

```swift
#Get(":id") { req in
    req.parameters.get("id")
}
```

If the dynamic name is intentional, wrap just that expression in ``Bypass(as:_:)``:

```swift
#Get(":id") { req in
    let key = resolveParameterName()
    return #Bypass { req.parameters.get(key) }
}
```

## Forwarded Parameters

When a child route collection is registered under a parent path, Swift macros
cannot pass that parent path into the child router's expansion. Declare those
inherited parameter names with ``ForwardParameters(_:)``.

```swift
@Router("users")
struct UserRoutes {
    #ForwardParameters("tenantID")

    #Get(":id") { req in
        let tenantID = try req.parameters.require("tenantID") // Now "tenantID" is a valid parameter
        let id = try req.parameters.require("id")
        return "\(tenantID)/\(id)"
    }
}
```

## Downgrading Diagnostics

Missing literal parameters are errors by default. Dynamic parameter names are
warnings by default.

Use ``DisableParameterCheck(as:)`` with `.warning` when a router or route should
still show likely path mismatches without failing compilation. In warning mode,
missing literal parameters become warnings and dynamic-name warnings are
suppressed.

```swift
@DisableParameterCheck(as: .warning)
@Router("legacy")
struct LegacyRoutes {
    #Get(":id") { req in
        let key = resolveParameterName()
        let dynamic = req.parameters.get(key) // Nothing here...
        let slug = try req.parameters.require("slug") // This is a warning
        return dynamic ?? slug
    }
}
```

Use the default `.error` mode to fully disable checking:

```swift
@DisableParameterCheck
@Router("legacy")
struct LegacyRoutes {
    #Get(":id") { req in
        try req.parameters.require("runtimeOnly") // No warning or error
    }
}
```

## Local Bypass

Use ``Bypass(as:_:)`` when only one expression should be excluded from static
analysis.

```swift
#Get(":id") { req in
    let key = resolveParameterName()
    return #Bypass {
        req.parameters.get(key)
    }
}
```

Use `#Bypass(as: .warning)` to keep a local missing-parameter diagnostic but
downgrade it to a warning:

```swift
#Get(":id") { req in
    return #Bypass(as: .warning) {
        try req.parameters.require("slug")
    }
}
```

## Topics

### Static Checking Controls

- ``ForwardParameters(_:)``
- ``DisableParameterCheck(as:)``
- ``Bypass(as:_:)``
