//
//  Router+StaticCheck.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 12/06/2026
//

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
public macro DisableParameterCheck(as severity: StaticCheckSeverity = .none) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

