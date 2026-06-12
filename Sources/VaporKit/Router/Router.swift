//
//  Router.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 27/03/2026
//

import Vapor

/// Defines a route collection from a nominal type.
///
/// Attach `@Router` to a struct or class that declares VaporKit route macros.
/// The macro synthesizes `boot(routes:)` and adds `Vapor.RouteCollection`
/// conformance. The optional URL is used as the base path for every route and
/// registered child route collection in the router.
///
/// - Parameter url: The optional base URL path for the router.
@attached(member, names: named(boot), prefixed(`$`))
@attached(extension, conformances: RouteCollection)
@attached(peer, names: prefixed(`$`))
public macro Router(_ url: StaticString? = nil) = #externalMacro(module: "VaporKitMacros", type: "RouterMacro")

// MARK: - Handler Declaration

/// Declares a route for an explicit HTTP method.
///
/// Use `#On` inside an ``Router(_:)`` type when the route method is not covered by a
/// method-specific helper. The trailing closure becomes the generated route
/// handler and may use an explicit request parameter or `$0`.
///
/// - Parameters:
///   - url: The optional URL path relative to the enclosing router.
///   - method: The HTTP method used to register the route.
///   - action: The async route handler body.
@freestanding(declaration)
public macro On<T: AsyncResponseEncodable>(
    _ url: StaticString? = nil,
    method: HTTPMethod,
    action: (Request) async throws -> T
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

/// Declares a `GET` route.
///
/// Use `#Get` inside an ``Router(_:)`` type to register a `GET` handler. The
/// trailing closure becomes the generated route handler and may use an explicit
/// request parameter or `$0`.
///
/// - Parameters:
///   - url: The optional URL path relative to the enclosing router.
///   - action: The async route handler body.
@freestanding(declaration)
public macro Get<T: AsyncResponseEncodable>(
    _ url: StaticString? = nil,
    action: (Request) async throws -> T
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

/// Declares a `POST` route.
///
/// Use `#Post` inside an ``Router(_:)`` type to register a `POST` handler. The
/// trailing closure becomes the generated route handler and may use an explicit
/// request parameter or `$0`.
///
/// - Parameters:
///   - url: The optional URL path relative to the enclosing router.
///   - action: The async route handler body.
@freestanding(declaration)
public macro Post<T: AsyncResponseEncodable>(
    _ url: StaticString? = nil,
    action: (Request) async throws -> T
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

/// Declares a `PUT` route.
///
/// Use `#Put` inside an ``Router(_:)`` type to register a `PUT` handler. The
/// trailing closure becomes the generated route handler and may use an explicit
/// request parameter or `$0`.
///
/// - Parameters:
///   - url: The optional URL path relative to the enclosing router.
///   - action: The async route handler body.
@freestanding(declaration)
public macro Put<T: AsyncResponseEncodable>(
    _ url: StaticString? = nil,
    action: (Request) async throws -> T
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

/// Declares a `DELETE` route.
///
/// Use `#Delete` inside an ``Router(_:)`` type to register a `DELETE` handler. The
/// trailing closure becomes the generated route handler and may use an explicit
/// request parameter or `$0`.
///
/// - Parameters:
///   - url: The optional URL path relative to the enclosing router.
///   - action: The async route handler body.
@freestanding(declaration)
public macro Delete<T: AsyncResponseEncodable>(
    _ url: StaticString? = nil,
    action: (Request) async throws -> T
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

// MARK: - Typed Parameter Injection

/// Marks a typed handler function as a route for an explicit HTTP method.
///
/// Attach `@On` to a function inside a ``Router(_:)`` type when the route
/// method is not covered by a method-specific helper. The function must accept
/// a `Request` or `Vapor.Request` parameter first. Additional route path
/// parameters must be marked with ``Path``.
///
/// ``Router(_:)`` registers a generated Vapor route handler that receives only
/// the request, extracts every ``Path`` value from `request.parameters`, and
/// then calls the annotated function.
///
/// ```swift
/// @On("reports/:id/rebuild", method: .PATCH)
/// func rebuild(req: Request, @Path("id") id: UUID) async throws -> HTTPStatus {
///     try await rebuildReport(id, on: req.db)
///     return .accepted
/// }
/// ```
///
/// - Parameters:
///   - url: The optional URL path relative to the enclosing router.
///   - method: The HTTP method used to register the route.
@attached(peer)
public macro On(
    _ url: StaticString? = nil,
    method: HTTPMethod
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

/// Marks a typed handler function as a `GET` route.
///
/// Attach `@Get` to a function inside a ``Router(_:)`` type. The first
/// function parameter must be `Request` or `Vapor.Request`; additional path
/// parameters are injected from the matched route when they are marked with
/// ``Path``.
///
/// ```swift
/// @Get("users/:id")
/// func find(req: Request, @Path("id") id: UUID) async throws -> UserDTO {
///     try await loadUser(id, on: req.db)
/// }
/// ```
///
/// - Parameter url: The optional URL path relative to the enclosing router.
@attached(peer)
public macro Get(
    _ url: StaticString? = nil
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

/// Marks a typed handler function as a `POST` route.
///
/// Use `@Post` when a typed handler function should be registered for `POST`.
/// The generated route handler extracts any ``Path`` parameters before calling
/// the annotated function.
///
/// ```swift
/// @Post("users/:id/sessions")
/// func createSession(req: Request, @Path("id") id: UUID) async throws -> SessionDTO {
///     try await createSession(for: id, on: req.db)
/// }
/// ```
///
/// - Parameter url: The optional URL path relative to the enclosing router.
@attached(peer)
public macro Post(
    _ url: StaticString? = nil
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

/// Marks a typed handler function as a `PUT` route.
///
/// Use `@Put` when a typed handler function should be registered for `PUT`.
/// Path parameters in the function signature must be marked with ``Path`` and
/// declared in the route URL.
///
/// ```swift
/// @Put("users/:id")
/// func replace(req: Request, @Path("id") id: UUID) async throws -> UserDTO {
///     try await replaceUser(id, using: req)
/// }
/// ```
///
/// - Parameter url: The optional URL path relative to the enclosing router.
@attached(peer)
public macro Put(
    _ url: StaticString? = nil
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

/// Marks a typed handler function as a `DELETE` route.
///
/// Use `@Delete` when a typed handler function should be registered for
/// `DELETE`. The generated route handler keeps the annotated function's
/// request label and passes injected ``Path`` values by their original
/// parameter labels.
///
/// ```swift
/// @Delete("users/:id")
/// func remove(_ req: Request, @Path("id") id: UUID) async throws -> HTTPStatus {
///     try await deleteUser(id, on: req.db)
///     return .noContent
/// }
/// ```
///
/// - Parameter url: The optional URL path relative to the enclosing router.
@attached(peer)
public macro Delete(
    _ url: StaticString? = nil
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

// MARK: - Register Macro

/// Marks an existing function as a route handler.
///
/// Attach `@RouteHandler` to a function inside an ``Router(_:)`` type when the
/// function should be registered directly instead of using a freestanding route
/// macro. The function must accept exactly one `Request` or `Vapor.Request`
/// parameter.
///
/// - Parameters:
///   - url: The optional URL path relative to the enclosing router.
///   - method: The HTTP method used to register the route.
@attached(peer)
public macro RouteHandler(
    _ url: StaticString? = nil,
    method: HTTPMethod
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

/// Marks an existing function as a route handler with path segments.
///
/// Attach `@RouteHandler` to a function inside an ``Router(_:)`` type when the route
/// path is easier to express as multiple static string segments. The function
/// must accept exactly one `Request` or `Vapor.Request` parameter.
///
/// - Parameters:
///   - url: The URL path segments relative to the enclosing router.
///   - method: The HTTP method used to register the route.
@attached(peer)
public macro RouteHandler(
    _ url: StaticString...,
    method: HTTPMethod
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

// MARK: - Middleware

/// Applies middleware to a route declaration.
///
/// Attach `@Middleware` to a freestanding route macro or
/// ``RouteHandler(_:method:)-(StaticString?,_)`` function. The route is registered
/// on `routes.grouped(...)` with the supplied middleware instances.
///
/// - Parameter middlewares: The middleware instances to apply to the route.
@attached(peer)
public macro Middleware(_ middlewares: any Middleware...) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

// MARK: - Children Controller Registeration

/// Registers child route collections.
///
/// Use `#Register` inside an ``Router(_:)`` type to register one or more child
/// `RouteCollection` values. The enclosing router's base path is applied to the
/// registration.
///
/// - Parameter router: The child route collections to register.
@freestanding(declaration)
public macro Register(_ router: any RouteCollection...) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")
