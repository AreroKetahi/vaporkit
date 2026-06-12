//
//  Router+WebSocket.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 12/06/2026
//

import Vapor

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
