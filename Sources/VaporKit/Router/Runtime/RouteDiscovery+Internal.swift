//
//  RouteDiscovery+Internal.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 15/05/2026
//

import Vapor

// MARK: - Frozen Types

public struct _RouteDescriptor {
    public let id: String
    public let routerName: String
    public let makeCollection: @Sendable () -> any RouteCollection
    
    public init(
        id: String,
        routerName: String,
        makeCollection: @Sendable @escaping () -> any RouteCollection
    ) {
        self.id = id
        self.routerName = routerName
        self.makeCollection = makeCollection
    }
}

public typealias _RouteRegisterAccessor = @convention(c) (
    _ outValue: UnsafeMutableRawPointer,
    _ type: UnsafeRawPointer,
    _ hint: UnsafeRawPointer?,
    _ reserved: UInt
) -> CBool

public typealias _RouteRegisterRecord = (
    kind: UInt32,
    version: UInt32,
    accessor: _RouteRegisterAccessor?,
    context: UInt,
    reserved: UInt
)
