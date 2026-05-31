//
//  exports.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 31/05/2026
//

#if canImport(Vapor)
@_exported import Vapor
#else
#error("VaporKit requires Vapor, but Vapor is unavailable on this target platform.")
#endif
