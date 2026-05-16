//
//  GeneralMacros.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 01/04/2026
//

/// Bypasses syntax-only macro checks for a single expression.
///
/// Wrap an expression in `#Bypass` when a local static check is too narrow for a
/// specific expression. The macro expands to the wrapped expression, so runtime
/// behavior is unchanged while checks such as route-parameter validation ignore
/// the wrapped syntax.
///
/// - Parameters:
///   - severity: The highest severity to silence or downgrade.
///   - action: The expression to emit without local static checking.
/// - Returns: The value produced by `action`.
@freestanding(expression)
public macro Bypass<T>(as severity: StaticCheckSeverity = .error, _ action: () -> T) -> T = #externalMacro(module: "VaporKitMacros", type: "BypassMacro")

/// Marks a ``Router(_:)`` type for runtime auto-registration.
///
/// Attach `@AutoRegisterable` to a type that also uses ``Router(_:)`` when the
/// router should be discovered at runtime by
/// ``Vapor/Application/autoRegisterRouters()``. The annotated router must be
/// constructible with `init()` because auto-registration creates the route
/// collection before calling Vapor's `register(collection:)` API.
///
/// ```swift
/// @AutoRegisterable
/// @Router("api/todos")
/// struct TodoController {
///     #Get { req in
///         "ok"
///     }
/// }
/// ```
///
/// Call ``Vapor/Application/autoRegisterRouters()`` during application setup to
/// register every discovered auto-registerable router.
@attached(peer)
public macro AutoRegisterable() = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")
