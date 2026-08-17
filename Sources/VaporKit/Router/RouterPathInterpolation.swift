//
//  RouterPathInterpolation.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 12/08/2026
//

import Foundation

/// Builds the interpolation components of a ``RouterPath``.
public struct RouterPathInterpolation: StringInterpolationProtocol {
    public typealias StringLiteralType = String

    private(set) var _storage: [_RouterPathComponent]

    public mutating func appendLiteral(_ literal: StringLiteralType) {
        for path in literal.split(separator: "/") {
            self._storage.append(.literal(String(path)))
        }
    }

    public init(literalCapacity: Int, interpolationCount: Int) {
        self._storage = []
    }

    /// Appends a parameter decoded as a URL-encoded `Decodable` value.
    public mutating func appendInterpolation<T: Decodable>(
        _ name: StaticString,
        decoding type: T.Type
    ) {
        self._storage.append(.decodable(named: String(describing: name), as: type))
    }

    /// Appends a parameter converted with `LosslessStringConvertible`.
    public mutating func appendInterpolation<T: LosslessStringConvertible>(
        _ name: StaticString,
        converting type: T.Type
    ) {
        self._storage.append(
            .losslessStringConvertible(named: String(describing: name), as: type)
        )
    }

    /// Appends a named parameter using VaporKit's existing conversion behavior.
    public mutating func appendInterpolation(key name: StaticString) {
        self._storage.append(.label(String(describing: name)))
    }
}
