//
//  ValidationRule+Expression.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 31/05/2026
//

/// Negates a validation rule.
///
/// Use `!` to render Vapor's rule negation for a `ValidationRule`.
///
/// - Parameter rule: The rule to negate.
/// - Returns: A validation rule that renders the negated expression.
public prefix func ! (rule: ValidationRule) -> ValidationRule {
    .init(kind: .not(rule))
}

/// Combines two validation rules with logical AND.
///
/// Use `&&` to require both validation rules to pass.
///
/// - Parameters:
///   - lhs: The left-hand validation rule.
///   - rhs: The right-hand validation rule.
/// - Returns: A validation rule that renders the conjunction.
public func && (lhs: ValidationRule, rhs: ValidationRule) -> ValidationRule {
    .init(kind: .and(lhs, rhs))
}

/// Combines two validation rules with logical OR.
///
/// Use `||` to accept values that satisfy either validation rule.
///
/// - Parameters:
///   - lhs: The left-hand validation rule.
///   - rhs: The right-hand validation rule.
/// - Returns: A validation rule that renders the disjunction.
public func || (lhs: ValidationRule, rhs: ValidationRule) -> ValidationRule {
    .init(kind: .or(lhs, rhs))
}
