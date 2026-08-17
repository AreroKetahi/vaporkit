//
//  VaporAppManifest.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 13/07/2026
//

import Vapor

/// An immutable description of a Vapor application's startup behavior.
///
/// A manifest runs configuration stages in declaration order before entering
/// the application lifecycle. Lifecycle handlers receive boot callbacks in
/// declaration order and shutdown callbacks in reverse order.
public struct VaporAppManifest: Sendable {
    /// The stages that configure the application before it boots.
    public let configurations: [any VaporAppConfiguration]

    /// The handlers that observe the application's runtime lifecycle.
    public let lifecycleHandlers: [any VaporAppLifecycleHandler]

    /// Creates a manifest from configuration and lifecycle stages.
    ///
    /// - Parameters:
    ///   - configurations: The configuration stages to execute in order.
    ///   - lifecycleHandlers: The lifecycle handlers to notify in order during
    ///     boot and in reverse order during shutdown.
    public init(
        configurations: [any VaporAppConfiguration] = [],
        lifecycleHandlers: [any VaporAppLifecycleHandler] = []
    ) {
        self.configurations = configurations
        self.lifecycleHandlers = lifecycleHandlers
    }

    func configure(_ application: Application) async throws {
        for configuration in configurations {
            try await configuration.configure(application)
        }
    }

    func willBoot(_ application: Application) async throws {
        for handler in lifecycleHandlers {
            try await handler.willBoot(application)
        }
    }

    func didBoot(_ application: Application) async throws {
        for handler in lifecycleHandlers {
            try await handler.didBoot(application)
        }
    }

    func shutdown(_ application: Application) async throws {
        for handler in lifecycleHandlers.reversed() {
            try await handler.shutdown(application)
        }
    }
}

/// A stage that configures a Vapor application before its lifecycle begins.
///
/// Configuration is a setup phase, not a lifecycle callback. If a
/// configuration creates temporary resources before throwing an error, it is
/// responsible for releasing those resources before returning.
public protocol VaporAppConfiguration: Sendable {
    /// Applies the configuration to an application.
    ///
    /// - Parameter application: The application being prepared for boot.
    func configure(_ application: Application) async throws
}

/// An object that observes the runtime lifecycle of a Vapor application.
///
/// Lifecycle handling begins after every ``VaporAppConfiguration`` completes
/// successfully.
public protocol VaporAppLifecycleHandler: Sendable {
    /// Performs work immediately before Vapor boots the application.
    ///
    /// - Parameter application: The application that is about to boot.
    func willBoot(_ application: Application) async throws

    /// Performs work after Vapor boots the application.
    ///
    /// - Parameter application: The application that finished booting.
    func didBoot(_ application: Application) async throws

    /// Releases lifecycle resources before the application shuts down.
    ///
    /// Manifest shutdown callbacks run in reverse declaration order.
    ///
    /// - Parameter application: The application that is shutting down.
    func shutdown(_ application: Application) async throws
}

public extension VaporAppLifecycleHandler {
    func willBoot(_ application: Application) async throws {}
    func didBoot(_ application: Application) async throws {}
    func shutdown(_ application: Application) async throws {}
}
