//
//  Router+Helper.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 12/06/2026
//

// MARK: Path

/// Marks a typed handler function parameter as a Vapor route path parameter.
///
/// Use `@Path` on parameters after the request parameter in a typed route
/// handler. The wrapped value is supplied by the ``Router(_:)`` macro's
/// generated route handler, which reads the named value from
/// `Request.parameters`.
///
/// ```swift
/// @Get("users/:id")
/// func find(req: Request, @Path("id") id: UUID) async throws -> UserDTO {
///     try await loadUser(id, on: req.db)
/// }
/// ```
///
/// If no name is supplied, the router macro uses the wrapped parameter's
/// local name. For example, `@Path id: UUID` reads `":id"`, and
/// `@Path of key: UUID` reads `":key"`.
///
/// `Value` must conform to `LosslessStringConvertible` because Vapor route
/// parameters are parsed with `Request.parameters.require(_:as:)`. `@Path`
/// itself does not parse the request, decode content, or change the value; it
/// is a marker wrapper used by the router macro.
@propertyWrapper
public struct Path<Value> where Value: LosslessStringConvertible {
    /// The typed value injected from the matched route parameter.
    public let wrappedValue: Value

    /// Creates a path parameter wrapper.
    ///
    /// This initializer is used when Swift applies the property wrapper to the
    /// original handler function. The optional `name` argument is read by
    /// ``Router(_:)`` during macro expansion and should match a `:name`
    /// segment in the route URL. When `name` is omitted, the macro uses the
    /// wrapped parameter's local name.
    ///
    /// - Parameters:
    ///   - wrappedValue: The already-converted route parameter value.
    ///   - name: The route parameter name without the leading colon.
    public init(wrappedValue: Value, _ name: StaticString? = nil) {
        self.wrappedValue = wrappedValue
    }
}

// MARK: Query

/// Marks a typed handler function parameter as a Vapor request query value.
///
/// Use `@Query` on parameters after the request parameter in a typed route
/// handler. Without a key, the generated route handler decodes the full query
/// string into the wrapped type:
///
/// ```swift
/// @Get("search")
/// func search(req: Request, @Query input: SearchQuery) throws -> [Result] {
///     try find(input, on: req)
/// }
/// ```
///
/// Pass a key to decode one value from the query container. Dots and slashes in
/// the key are treated as key-path separators, so `@Query("user.name")` and
/// `@Query("user/name")` both read `req.query.get(String.self, at: "user",
/// "name")`.
///
/// `Value` must conform to `Decodable` because Vapor query values are parsed
/// with `Request.query.decode(_:)` or `Request.query.get(_:at:)`. `@Query`
/// itself does not parse the request; it is a marker wrapper used by the router
/// macro.
///
/// Optional parameters and parameters with default values are decoded with
/// `try?`. Defaults are applied when the generated wrapper calls the original
/// function.
@propertyWrapper
public struct Query<Value> where Value: Decodable {
    /// The typed value injected from the request query string.
    public let wrappedValue: Value

    /// Creates a query parameter wrapper.
    ///
    /// This initializer is used when Swift applies the property wrapper to the
    /// original handler function. The optional `key` argument is read by
    /// ``Router(_:)`` during macro expansion. When `key` is omitted, the macro
    /// decodes the full query string into `Value`.
    ///
    /// - Parameters:
    ///   - wrappedValue: The already-decoded query value.
    ///   - key: An optional query key or key path.
    public init(wrappedValue: Value, _ key: StaticString? = nil) {
        self.wrappedValue = wrappedValue
    }
}

// MARK: Content Body

/// Marks a typed handler function parameter as a decoded request body value.
///
/// Use `@ContentBody` on a parameter after the request parameter in a typed route
/// handler. The generated route handler decodes the request body with
/// `Request.content.decode(_:)` and passes the decoded value to the original
/// function.
///
/// ```swift
/// @Post("users")
/// func create(req: Request, @ContentBody input: CreateUserBody) async throws -> UserDTO {
///     try await createUser(input, on: req.db)
/// }
/// ```
///
/// `Value` must conform to `Decodable` because Vapor content values are parsed
/// with `Request.content.decode(_:)`. `@ContentBody` itself does not parse the
/// request; it is a marker wrapper used by the router macro.
///
/// Optional parameters and parameters with default values are decoded with
/// `try?`. Defaults are applied when the generated wrapper calls the original
/// function.
@propertyWrapper
public struct ContentBody<Value> where Value: Decodable {
    /// The typed value injected from the request body.
    public let wrappedValue: Value

    /// Creates a content parameter wrapper.
    ///
    /// This initializer is used when Swift applies the property wrapper to the
    /// original handler function. ``Router(_:)`` reads the wrapper during macro
    /// expansion and generates the body decoding code.
    ///
    /// - Parameter wrappedValue: The already-decoded request body value.
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}

// MARK: - Advanced Part

/// Marks a typed handler function parameter as an authenticated Vapor user.
///
/// Use `@Auth` on parameters after the request parameter in a typed route
/// handler. For required values, the generated route handler reads the value
/// with `Request.auth.require(_:)` and passes it to the original function.
///
/// ```swift
/// @Get("profile")
/// func profile(req: Request, @Auth user: User) async throws -> UserDTO {
///     try await loadProfile(for: user, on: req.db)
/// }
/// ```
///
/// Optional parameters use `Request.auth.get(_:)` instead:
///
/// ```swift
/// @Get("profile")
/// func profile(req: Request, @Auth user: User?) -> UserDTO? {
///     user.map(UserDTO.init)
/// }
/// ```
///
/// The wrapped type, or the wrapped type inside an optional, must conform to
/// `Authenticatable`. Configure authentication with normal Vapor middleware or
/// authenticators before this route runs.
@propertyWrapper
public struct Auth<Value> {
    /// The authenticated value injected from `Request.auth`.
    public let wrappedValue: Value

    /// Creates an authenticated value wrapper.
    ///
    /// This initializer is used when Swift applies the property wrapper to the
    /// original handler function. ``Router(_:)`` reads the wrapper during macro
    /// expansion and generates the authentication lookup code.
    ///
    /// - Parameter wrappedValue: The already-authenticated value.
    public init(wrappedValue: Value) where Value: Authenticatable {
        self.wrappedValue = wrappedValue
    }

    /// Creates an optional authenticated value wrapper.
    ///
    /// - Parameter wrappedValue: The optional authenticated value.
    public init<Wrapped>(wrappedValue: Wrapped?) where Value == Wrapped?, Wrapped: Authenticatable {
        self.wrappedValue = wrappedValue
    }
}
