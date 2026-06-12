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

@attached(peer)
public macro On(
    _ url: StaticString? = nil,
    method: HTTPMethod
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

@attached(peer)
public macro Get(
    _ url: StaticString? = nil
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

@attached(peer)
public macro Post(
    _ url: StaticString? = nil
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

@attached(peer)
public macro Put(
    _ url: StaticString? = nil
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

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
