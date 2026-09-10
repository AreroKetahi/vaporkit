# Injecting Values into Route Handlers

Decode path, query, content, cookie, header, and authentication values in a
handler's function signature.

## Overview

Router injection is available to method-based handlers declared with `@Get`,
`@Post`, `@Put`, `@Delete`, or `@On`. The first function parameter receives the
Vapor `Request`. Every remaining parameter uses an annotation that tells
VaporKit where and how to obtain its value.

```swift
@Router("users")
struct UserRoutes {
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
}
```

VaporKit generates a native Vapor handler that decodes these values before
calling the method. Required decoding failures retain Vapor's normal error
behavior. Optional and defaulted parameters allow the handler to provide its
own fallback.

### Path

Use ``Path`` for a named segment in the route URL. When the Swift parameter name
matches the path name, omit the annotation argument:

```swift
@Get(":id")
func show(request: Request, @Path id: UUID) async throws -> UserDTO {
    try await loadUser(id, on: request.db)
}
```

Supply a name when the route and Swift names differ:

```swift
@Get(":user_id")
func show(request: Request, @Path("user_id") id: UUID) -> String {
    id.uuidString
}
```

The value type must conform to `LosslessStringConvertible`. A missing or invalid
required value throws through Vapor's `Request.parameters.require` behavior.
Path names also participate in VaporKit's compile-time checks; see
<doc:StaticRouteParameterChecking>.

Use ``RouterPath`` interpolation when the route declaration must select an
explicit parsing strategy:

```swift
@Get("pages/\("page", converting: Int.self)")
func page(request: Request, @Path page: Int) -> String {
    String(page)
}

@Get("users/\("id", decoding: UUID.self)")
func show(request: Request, @Path id: UUID) -> String {
    id.uuidString
}
```

`converting:` uses `LosslessStringConvertible`; `decoding:` URL-decodes a
`Decodable` value. An invalid explicitly converted or decoded value produces
`422 Unprocessable Entity`.

### Query

Use ``Query`` without a key to decode the complete query string into a model:

```swift
struct SearchQuery: Decodable {
    var term: String
    var limit: Int?
}

@Get("search")
func search(request: Request, @Query query: SearchQuery) -> String {
    "\(query.term):\(query.limit ?? 20)"
}
```

Provide a key to decode one value. Dots and slashes both describe nested key
paths:

```swift
@Get("search")
func search(
    request: Request,
    @Query("filter.name") name: String,
    @Query("page/number") page: Int = 1
) -> String {
    "\(name):\(page)"
}
```

A required query parameter propagates Vapor's decoding error. An optional
parameter receives `nil` when the value is absent or invalid. A defaulted
parameter uses its default in the same situation.

### Content Body

Use ``ContentBody`` to decode `Request.content` into a `Decodable` type:

```swift
struct CreateUserRequest: Content {
    var name: String
    var email: String
}

@Post
func create(
    request: Request,
    @ContentBody body: CreateUserRequest
) async throws -> UserDTO {
    try await createUser(from: body, on: request.db)
}
```

A required body propagates Vapor's content-decoding error. An optional body
receives `nil` on decoding failure, while a defaulted body substitutes its
default value:

```swift
@Post("preview")
func preview(
    request: Request,
    @ContentBody body: PreviewRequest = .empty
) -> PreviewResponse {
    renderPreview(body)
}
```

Use at most one content-body parameter when generating OpenAPI. If the handler
needs a different documented body, override it with
`OpenAPIRequest(body:contentType:required:)`.

### Cookie

Use ``Cookie`` without an argument to receive all parsed cookies:

```swift
@Get("preferences")
func preferences(
    request: Request,
    @Cookie cookies: [String: String]
) -> String {
    cookies["theme"] ?? "system"
}
```

For one cookie, choose decoding for a `Decodable` type or conversion for a
`LosslessStringConvertible` type:

```swift
@Get("preferences")
func preferences(
    request: Request,
    @Cookie(decoding: "profile") profile: ProfileCookie?,
    @Cookie(converting: "page") page: Int?
) -> String {
    "\(profile?.name ?? "anonymous"):\(page ?? 1)"
}
```

A missing cookie or failed conversion produces `nil`. Vapor exposes one parsed
value per cookie name.

### Header

Use ``Header`` without an argument to receive the complete `HTTPHeaders`
collection:

```swift
@Get("inspect")
func inspect(request: Request, @Header headers: HTTPHeaders) -> Int {
    headers.count
}
```

Use `key:` to preserve every raw value for one case-insensitive header name:

```swift
@Get("inspect")
func inspect(
    request: Request,
    @Header(key: "Accept") acceptedTypes: [String]
) -> [String] {
    acceptedTypes
}
```

Repeated headers remain separate and in request order. A missing header
produces an empty array, and comma-containing values aren't split.

Use `decoding:` or `converting:` to process each raw value independently:

```swift
@Get("retries")
func retries(
    request: Request,
    @Header(converting: "X-Retry-Count") values: [Int?]
) -> [Int?] {
    values
}
```

Each header value produces one array element. A failed conversion becomes
`nil` at the same position without discarding the other values.

### Auth

Use ``Auth`` for a value previously attached by Vapor authentication
middleware:

```swift
@Get("profile")
func profile(request: Request, @Auth user: User) async throws -> UserDTO {
    try await loadProfile(for: user, on: request.db)
}
```

A required value uses `Request.auth.require` and throws when that type isn't
authenticated. An optional value uses `Request.auth.get`:

```swift
@Get("greeting")
func greeting(request: Request, @Auth user: User?) -> String {
    "Hello, \(user?.name ?? "guest")"
}
```

A defaulted authentication parameter uses its default when no matching value
is attached. Configure authenticators and authentication middleware with
Vapor's normal APIs before the route executes.

### Combine Annotations

Annotations can be combined in any order after the request parameter. Keep
transport decoding at the function boundary and pass ordinary Swift values to
the handler body:

```swift
@Post("projects/:projectID/comments")
func comment(
    request: Request,
    @Path projectID: UUID,
    @Query("notify") notify: Bool = true,
    @ContentBody body: NewComment,
    @Cookie(converting: "timezone") timezone: Int?,
    @Header(key: "Accept-Language") languages: [String],
    @Auth author: User
) async throws -> CommentDTO {
    try await createComment(
        body,
        in: projectID,
        by: author,
        notify: notify,
        timezone: timezone,
        languages: languages,
        on: request.db
    )
}
```

## See Also

- <doc:UsingParameterInFunction>
- <doc:StaticRouteParameterChecking>
- <doc:OpenAPIOverview>
