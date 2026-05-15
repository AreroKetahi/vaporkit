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
@attached(member, names: named(boot), arbitrary)
@attached(extension, conformances: RouteCollection)
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

/// Declares a WebSocket route.
///
/// Use `#WebSocket` inside an ``Router(_:)`` type to register a WebSocket endpoint.
/// The primary trailing closure is used as `shouldUpgrade` when `didUpgrade` is
/// supplied; otherwise the closure is treated as the upgrade body. WebSocket
/// events are declared with ``OnText(action:)``, ``OnBinary(action:)``, and
/// ``OnClose(action:)`.
///
/// - Parameters:
///   - url: The URL path segments relative to the enclosing router.
///   - maxFrameSize: The maximum accepted WebSocket frame size.
///   - shouldUpgrade: The async upgrade decision callback.
///   - didUpgrade: The declaration body for WebSocket event handlers.
@freestanding(declaration)
public macro WebSocket(
    _ url: StaticString...,
    maxFrameSize: WebSocketMaxFrameSize = .default,
    shouldUpgrade: @escaping @Sendable (Request) async throws -> HTTPHeaders? = { _ in [:] },
    didUpgrade: () -> Void
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

/// Declares a WebSocket text-message handler.
///
/// Use `#OnText` inside a ``WebSocket(_:maxFrameSize:shouldUpgrade:didUpgrade:)``
/// upgrade body. The handler may declare explicit `(WebSocket, String)`
/// parameters or use `$0` and `$1`, which are rewritten to generated unique names.
///
/// - Parameter action: The async text-message callback.
@freestanding(expression)
public macro OnText(
    action: @escaping @Sendable (WebSocket, String) async -> Void
) = #externalMacro(module: "VaporKitMacros", type: "EmptyExpressionMacro")

/// Declares a WebSocket binary-message handler.
///
/// Use `#OnBinary` inside a ``WebSocket(_:maxFrameSize:shouldUpgrade:didUpgrade:)``
/// upgrade body. The handler may declare explicit `(WebSocket, ByteBuffer)`
/// parameters or use `$0` and `$1`, which are rewritten to generated unique names.
///
/// - Parameter action: The async binary-message callback.
@freestanding(expression)
public macro OnBinary(
    action: @escaping @Sendable (WebSocket, ByteBuffer) async -> Void
) = #externalMacro(module: "VaporKitMacros", type: "EmptyExpressionMacro")

/// Declares a WebSocket close handler.
///
/// Use `#OnClose` inside a ``WebSocket(_:maxFrameSize:shouldUpgrade:didUpgrade:)``
/// upgrade body to run code when the WebSocket closes. The closure must not
/// declare parameters.
///
/// - Parameter action: The close callback body.
@freestanding(expression)
public macro OnClose(
    action: @escaping @Sendable () -> Void
) = #externalMacro(module: "VaporKitMacros", type: "EmptyExpressionMacro")

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

/// Applies middleware to a route declaration.
///
/// Attach `@Middleware` to a freestanding route macro or
/// ``RouteHandler(_:method:)-(StaticString?,_)`` function. The route is registered
/// on `routes.grouped(...)` with the supplied middleware instances.
///
/// - Parameter middlewares: The middleware instances to apply to the route.
@attached(peer)
public macro Middleware(_ middlewares: any Middleware...) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

/// Registers child route collections.
///
/// Use `#Register` inside an ``Router(_:)`` type to register one or more child
/// `RouteCollection` values. The enclosing router's base path is applied to the
/// registration.
///
/// - Parameter router: The child route collections to register.
@freestanding(declaration)
public macro Register(_ router: any RouteCollection...) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

// MARK: - Parameter Static Check Support

/// Declares route parameters forwarded from an outer router.
///
/// Use `#ForwardParameters` inside an ``Router(_:)`` type when this router is
/// registered below a parent path that contains route parameters. The declared
/// names are accepted by static checks for `req.parameters.get` and
/// `req.parameters.require`.
///
/// - Parameter parameters: The forwarded route parameter names.
@freestanding(declaration)
public macro ForwardParameters(_ parameters: StaticString...) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

/// Disables static route-parameter checking.
///
/// Attach `@DisableParameterCheck` to an ``Router(_:)`` type to disable checks for
/// the whole router, or attach it to a route declaration or ``RouteHandler(_:method:)-(StaticString?,_)``
/// function to disable checks for only that route.
///
/// - Parameter severity: The highest severity to silence or downgrade.
@attached(peer)
public macro DisableParameterCheck(as severity: StaticCheckSeverity = .error) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")
