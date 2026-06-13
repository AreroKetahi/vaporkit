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
