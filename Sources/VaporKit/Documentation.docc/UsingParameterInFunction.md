# Using Parameters in Functions

Decode request values directly into a route handler's parameters.

## Overview

Attach a full-featured route macro to a method inside a ``Router(_:)`` type.
The first parameter is the Vapor `Request`; mark every decoded parameter with
the wrapper that identifies its source.

```swift
@Router("users")
struct UserRoutes {
    @Post(":id")
    func update(
        request: Request,
        @Path id: UUID,
        @Query("notify") notify: Bool = false,
        @ContentBody body: UpdateUserRequest,
        @Header(converting: "X-Retry-Count") retries: [Int?],
        @Auth user: User
    ) async throws -> UserDTO {
        try await updateUser(id, with: body, by: user, notify: notify, on: request.db)
    }
}
```

VaporKit generates the request decoding and native Vapor route registration.
It doesn't change the handler's return type or error behavior.

For the decoding and failure behavior of every parameter annotation, see
<doc:RouterInjection>.

### Select a Parameter Source

| Wrapper         | Source               | Behavior                                                              |
| --------------- | -------------------- | --------------------------------------------------------------------- |
| ``Path``        | `Request.parameters` | Converts a named path segment to a `LosslessStringConvertible` value. |
| ``Query``       | `Request.query`      | Decodes the full query or a dotted/slashed key path.                  |
| ``ContentBody`` | `Request.content`    | Decodes the request body.                                             |
| ``Cookie``      | `Request.cookies`    | Reads all cookies or decodes one named cookie.                        |
| ``Header``      | `Request.headers`    | Preserves repeated values for a named header.                         |
| ``Auth``        | `Request.auth`       | Gets or requires an authenticated value.                              |

Omit a ``Path`` name when it matches the Swift parameter name. Use optional
parameters or default values when absence should not fail query, body, cookie,
header, or authentication decoding.

### Control Path Conversion

The familiar `":id"` syntax uses the type declared by ``Path``. Use
``RouterPath`` interpolation when the path itself needs to state how a segment
is parsed:

```swift
@Get("pages/\(\"page\", converting: Int.self)")
func page(request: Request, @Path page: Int) -> String {
    String(page)
}
```

Use `key:` for Vapor's normal parameter conversion, `converting:` for
`LosslessStringConvertible`, and `decoding:` for a URL-decoded `Decodable`
value. Invalid explicit conversion or decoding returns `422 Unprocessable
Entity`.

### Check Path Names

Path wrappers participate in the same syntax-only checks as closure handlers.
See <doc:StaticRouteParameterChecking> for forwarded parameters, diagnostic
severity, and local bypasses.

## Topics

### Parameter Wrappers

- ``Path``
- ``Query``
- ``ContentBody``
- ``Cookie``
- ``Header``
- ``Auth``

## See Also

- <doc:RouterInjection>
- <doc:StaticRouteParameterChecking>
