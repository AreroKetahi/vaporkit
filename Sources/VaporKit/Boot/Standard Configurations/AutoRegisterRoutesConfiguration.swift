//
//  AutoRegisterRoutesConfiguration.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 14/07/2026
//

/// A configuration that registers every discoverable VaporKit router.
///
/// Add ``default`` to a ``VaporAppManifest`` to perform automatic route
/// registration before the application boots.
public struct AutoRegisterRoutesConfiguration: VaporAppConfiguration {
    /// Registers the routers discovered in the current process.
    ///
    /// - Parameter application: The application that receives the routes.
    public func configure(_ application: Application) async throws {
        try application.autoRegisterRouters()
    }

    /// The standard automatic route registration configuration.
    public static let `default` = AutoRegisterRoutesConfiguration()
}
