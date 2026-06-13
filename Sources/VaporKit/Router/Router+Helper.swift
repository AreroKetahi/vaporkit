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

