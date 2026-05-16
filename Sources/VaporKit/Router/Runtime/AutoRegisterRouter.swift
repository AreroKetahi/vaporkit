//
//  AutoRegisterRouter.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 15/05/2026
//

import Vapor

extension Application {
    /// Discovers and registers every router marked with ``AutoRegisterable()``.
    ///
    /// Call this method during application setup after importing VaporKit. It
    /// scans the runtime route metadata emitted for `@AutoRegisterable`
    /// ``Router(_:)`` types, creates each discovered route collection, and
    /// registers it through Vapor's `register(collection:)` API.
    ///
    /// ```swift
    /// import Vapor
    /// import VaporKit
    ///
    /// public func configure(_ app: Application) throws {
    ///     try app.autoRegisterRouters()
    /// }
    /// ```
    ///
    /// Routers are de-duplicated by their generated descriptor id. A router
    /// marked with ``AutoRegisterable()`` must support `init()`, because
    /// discovery constructs the route collection before registration.
    public func autoRegisterRouters() throws {
        self.logger.info("Starting auto-registerable router discovery...")
        var seen = Set<String>()
        
        for descriptor in _RouteDiscovery._discover() {
            guard seen.insert(descriptor.id).inserted else {
                continue
            }
            
            try self.register(collection: descriptor.makeCollection())
            self.logger.info("Auto-registerable router loaded: \(descriptor.id)")
        }
        self.logger.info("Successfully loaded \(seen.count) auto-registerable routers.")
    }
}
