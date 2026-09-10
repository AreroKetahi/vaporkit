# Checking Route Parameters at Compile Time

Catch mismatches between route paths and parameter access during macro expansion.

## Overview

VaporKit diagnoses a literal parameter name that isn't declared by its route:

```swift
#Get(":id") { request in
    try request.parameters.require("slug") // "slug" isn't in the route
}
```

The check recognizes direct `request.parameters.get` and
`request.parameters.require` calls, including shorthand closure arguments. It
also checks ``Path`` parameters on method-based handlers.

The analysis is intentionally syntax-only. It doesn't follow request aliases,
helper functions, or dynamically computed parameter names. Dynamic names
produce a warning because the compiler can't prove their value.

### Declare Parent Parameters

A child router's macro can't inspect the path of the parent that registers it.
Declare inherited names in the child:

```swift
@Router("users")
struct UserRoutes {
    #ForwardParameters("tenantID")

    #Get(":id") { request in
        let tenantID = try request.parameters.require("tenantID")
        let id = try request.parameters.require("id")
        return "\(tenantID)/\(id)"
    }
}
```

### Adjust a Diagnostic

Use ``DisableParameterCheck(as:)`` on a router or route to disable checks or
downgrade missing literals to warnings. Use ``Bypass(as:_:)`` for the smallest
dynamic expression that the checker should ignore:

```swift
let key = resolveParameterName()
let value = #Bypass { request.parameters.get(key) }
```

Prefer a literal or ``ForwardParameters(_:)`` whenever the parameter name is
known. A bypass is appropriate only when the name is genuinely dynamic.

## Topics

### Checking Controls

- ``ForwardParameters(_:)``
- ``DisableParameterCheck(as:)``
- ``Bypass(as:_:)``
- ``StaticCheckSeverity``
