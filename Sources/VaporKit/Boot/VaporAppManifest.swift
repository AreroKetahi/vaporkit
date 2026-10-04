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
    
    /// The providers used after command-line passthrough configuration.
    public let configReaderManifest: VaporConfigReaderManifest
    
    /// The server settings supplied when the application is created.
    public let serverConfiguration: ServerConfiguration
    
    /// The service settings supplied when the application is created.
    public let serviceConfiguration: Application.ServiceConfiguration

    /// Creates a manifest from configuration and lifecycle stages.
    ///
    /// - Parameters:
    ///   - configurations: The configuration stages to execute in order.
    ///   - lifecycleHandlers: The lifecycle handlers to notify in order during
    ///     boot and in reverse order during shutdown.
    ///   - configReader: The ordered configuration providers and optional reporter.
    ///   - serverConfiguration: The initial Vapor server settings.
    ///   - serviceConfiguration: The initial Vapor service settings.
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

/// Configuration sources for the application's startup reader.
///
/// The server command prepends its passthrough arguments to these providers.
/// See <doc:ApplicationEntryPoint> for configuration precedence and examples.
public struct VaporConfigReaderManifest: Sendable {
    /// Providers queried in declaration order after command-line arguments.
    public let configProviders: @Sendable () async throws -> [any ConfigProvider]
    /// An optional access reporter. The default server command does not yet use it.
    public let accessReporter: (any AccessReporter)?
    
    /// Describes configuration providers and an optional access reporter.
    ///
    /// - Parameters:
    ///   - providers: Sources queried in order until a value is found.
    ///   - accessReporter: A reporter for configuration access events.
    public init(providers: [any ConfigProvider], accessReporter: (any AccessReporter)? = nil) {
        self.configProviders = {
            providers
        }
        self.accessReporter = accessReporter
    }
    
    public init(providers: @Sendable @escaping () async throws -> [any ConfigProvider], accessReporter: (any AccessReporter)? = nil) {
        self.configProviders = providers
        self.accessReporter = accessReporter
    }
    
    /// Reads environment variables after command-line passthrough arguments.
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
/// This is an alias of `Vapor.LifecycleHandler`; new code can adopt the Vapor
/// protocol directly.
public typealias VaporAppLifecycleHandler = LifecycleHandler
