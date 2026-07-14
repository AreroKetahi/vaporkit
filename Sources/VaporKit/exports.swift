//
//  exports.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 31/05/2026
//

#if canImport(Vapor)
@_documentation(visibility: internal)
@_exported import Vapor
#else
#error("VaporKit requires Vapor, but Vapor is unavailable on this target platform.")
#endif

@_exported import VaporKitOpenAPI
