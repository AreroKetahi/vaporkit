//
//  ValidationMacros.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 27/03/2026
//

import Vapor

/// Generates Vapor validation support for a model type.
///
/// ## Overview
/// Attach `@ValidatableModel` to a struct or class that contains properties
/// annotated with `@Constraint`. The macro synthesizes `validations(_:)` and
/// adds `Vapor.Validatable` conformance.
@attached(member, names: named(validations))
@attached(extension, conformances: Vapor.Validatable)
public macro ValidatableModel() = #externalMacro(module: "VaporKitMacros", type: "ValidatableMacro")

/// Declares a validation constraint for a property.
///
/// ## Overview
/// Attach `@Constraint` to a stored property in a `@ValidatableModel` type. The
/// macro uses the supplied `ValidationRule` to generate a Vapor validation entry
/// for the property.
///
/// - Parameters:
///   - rule: The validation rule to apply to the property.
///   - required: Whether the property is required by the generated validation.
///   - message: An optional custom validation failure message.
@attached(peer)
public macro Constraint(
    _ rule: ValidationRule,
    required: Bool = true,
    message: StaticString? = nil
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")

/// Declares a custom validation constraint for a property.
///
/// ## Overview
/// Attach this overload of `@Constraint` to a stored property in a
/// `@ValidatableModel` type when validation requires a custom predicate. The
/// generated Vapor validation decodes the property as the supplied type and
/// evaluates the predicate.
///
/// - Parameters:
///   - type: The decodable type passed to the custom predicate.
///   - message: An optional custom validation failure message.
///   - body: The predicate that returns `true` for accepted values.
@attached(peer)
public macro Constraint<T: Decodable & Sendable>(
    validating type: T.Type,
    message: StaticString? = nil,
    with body: @escaping @Sendable (T) -> Bool
) = #externalMacro(module: "VaporKitMacros", type: "EmptyMacro")
