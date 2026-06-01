//
//  Validation+Predicate.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 31/05/2026
//

import Foundation

@available(macOS 14.0, *)
extension ValidationRule {
    /// Creates a validation rule backed by a Foundation predicate.
    ///
    /// The predicate expression is preserved by `@Constraint` and emitted into
    /// the generated Vapor validator expression.
    ///
    /// - Parameter predicate: The Foundation predicate used for validation.
    /// - Returns: A validation rule backed by the supplied predicate.
    public static func predicate<T: Sendable>(
        _ predicate: Predicate<T>
    ) -> Self {
        .init(kind: .predicate)
    }
}

@available(macOS 14.0, *)
extension Validator {
    /// Creates a Vapor validator backed by a Foundation predicate.
    ///
    /// Predicate evaluation failures are treated as validation failures.
    ///
    /// - Parameter predicate: The Foundation predicate used for validation.
    /// - Returns: A validator that succeeds when the predicate evaluates to `true`.
    public static func predicate(
        _ predicate: Predicate<T>
    ) -> Self {
        .custom("satisfies predicate", validationClosure: { value in
            do {
                return try predicate.evaluate(value)
            } catch {
                return false
            }
        })
    }
}
