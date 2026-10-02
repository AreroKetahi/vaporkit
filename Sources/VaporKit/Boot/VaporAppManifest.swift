//
//  VaporAppManifest.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 13/07/2026
//

import Vapor
import Configuration

/// An immutable description of a Vapor application's startup behavior.
///
/// A manifest runs configuration stages in declaration order before entering
/// the application lifecycle. Lifecycle handlers receive boot callbacks in
/// declaration order and shutdown callbacks in reverse order.
public struct VaporAppManifest: Sendable {
    /// The stages that configure the application before it boots.
    public let configurations: [any VaporAppConfiguration]

    /// The handlers that observe the application's runtime lifecycle.
    public let lifecycleHandlers: [any LifecycleHandler]
    
    public let configReaderManifest: VaporConfigReaderManifest
    
    public let serverConfiguration: ServerConfiguration
    
    public let serviceConfiguration: Application.ServiceConfiguration

    /// Creates a manifest from configuration and lifecycle stages.
    ///
    /// - Parameters:
    ///   - configurations: The configuration stages to execute in order.
    ///   - lifecycleHandlers: The lifecycle handlers to notify in order during
    ///     boot and in reverse order during shutdown.
    public init(
        configurations: [any VaporAppConfiguration] = [],
        lifecycleHandlers: [any LifecycleHandler] = [],
        configReader: VaporConfigReaderManifest = .default,
        serverConfiguration: ServerConfiguration = ServerConfiguration(),
        serviceConfiguration: Application.ServiceConfiguration = Application.ServiceConfiguration()
    ) {
        self.configurations = configurations
        self.lifecycleHandlers = lifecycleHandlers
        self.configReaderManifest = configReader
        self.serverConfiguration = serverConfiguration
        self.serviceConfiguration = serviceConfiguration
    }

    func _configure(_ application: Application) async throws {
        for configuration in configurations {
            try await configuration.configure(application)
        }
    }

    func _installLifecycleHandlers(on application: Application) {
        for handler in lifecycleHandlers {
            application.addLifecycleHandler(handler)
        }
    }
}

public struct VaporConfigReaderManifest: Sendable {
    public let configProviders: [any ConfigProvider]
    public let accessReporter: (any AccessReporter)?
    
    public init(providers: [any ConfigProvider], accessReporter: (any AccessReporter)? = nil) {
        self.configProviders = providers
        self.accessReporter = accessReporter
    }
    
    public static let `default` = VaporConfigReaderManifest(
        providers: [
            EnvironmentVariablesProvider(),
        ],
        accessReporter: nil
    )
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
///
/// - Important: In VaporKit 2.x, this type will represet to
/// `Vapor.LifecycleHandler`.
public typealias VaporAppLifecycleHandler = LifecycleHandler
