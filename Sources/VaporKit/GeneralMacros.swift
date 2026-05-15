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

@attached(peer)
public macro AutoRegisterable() = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")
