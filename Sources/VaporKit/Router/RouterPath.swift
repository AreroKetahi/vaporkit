//
//  RouterPath.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 13/08/2026
//

import Foundation

/// A statically analyzable route path used by VaporKit's attached route macros.
///
/// String interpolation declares captured path parameters and optionally selects
/// how ``Path`` values are parsed. Traditional `:name` segments remain supported.
public struct RouterPath {
    private var components: [_RouterPathComponent]
}

extension RouterPath: ExpressibleByStringLiteral {
    /// Creates a route path from traditional literal segments such as `"users/:id"`.
    public init(stringLiteral value: String) {
        self.components = value.split(separator: "/").map {
            .literal(String($0))
        }
    }
}

extension RouterPath: ExpressibleByStringInterpolation {
    /// Creates a route path from literal and parameter interpolation components.
    public init(stringInterpolation: RouterPathInterpolation) {
        self.components = stringInterpolation._storage
    }
}
