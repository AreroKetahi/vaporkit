//
//  AutoRegisterRouter.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 15/05/2026
//

import Vapor

extension Application {
    public func autoRegisterRouters() throws {
        var seen = Set<String>()
        
        for descriptor in _RouteDiscovery._discover() {
            guard seen.insert(descriptor.id).inserted else {
                continue
            }
            
            try self.register(collection: descriptor.makeCollection())
        }
    }
}
