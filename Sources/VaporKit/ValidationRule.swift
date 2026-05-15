//
//  ValidationRule.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 27/03/2026
//

import Foundation

/// Describes a Vapor validation rule expression.
///
/// ## Overview
/// `ValidationRule` is a syntax-level representation used by `@Constraint`.
/// Compose rules with the provided static members, factory methods, and boolean
/// operators to generate Vapor validation expressions.
public struct ValidationRule: Sendable, Equatable, Hashable, CustomStringConvertible {
    /// Describes a rendered validation-rule argument.
    ///
    /// ## Overview
    /// `Argument` stores the source representation for an argument passed to a
    /// validation rule factory, such as `.count(1...10)`.
    public struct Argument: Sendable, Equatable, Hashable, CustomStringConvertible {
        /// The rendered source description.
        ///
        /// ## Overview
        /// This value is emitted into the generated validation expression.
        public let description: String

        /// Creates a rendered validation-rule argument.
        ///
        /// ## Overview
        /// Use this initializer when constructing a custom `ValidationRule`
        /// value that needs a pre-rendered argument.
        ///
        /// - Parameter description: The source representation for the argument.
        public init(_ description: String) {
            self.description = description
        }
    }

    /// The structural form of a validation rule.
    ///
    /// ## Overview
    /// `Kind` stores either a named Vapor validator, a validator call, or a
    /// boolean composition of other validation rules.
    public indirect enum Kind: Sendable, Equatable, Hashable {
        /// A named validator member.
        ///
        /// ## Overview
        /// Represents validators such as `.email` or `.alphanumeric`.
        case member(String)

        /// A validator call with rendered arguments.
        ///
        /// ## Overview
        /// Represents validators such as `.count(1...10)` or `.in("a", "b")`.
        case call(name: String, arguments: [Argument])

        /// The negation of another validation rule.
        ///
        /// ## Overview
        /// Represents `!rule` in a generated validation expression.
        case not(ValidationRule)

        /// A conjunction of two validation rules.
        ///
        /// ## Overview
        /// Represents `lhs && rhs` in a generated validation expression.
        case and(ValidationRule, ValidationRule)

        /// A disjunction of two validation rules.
        ///
        /// ## Overview
        /// Represents `lhs || rhs` in a generated validation expression.
        case or(ValidationRule, ValidationRule)
    }

    /// The structural form of this rule.
    ///
    /// ## Overview
    /// The macro renders `kind` into the Vapor validation expression used by
    /// generated `validations(_:)`.
    public let kind: Kind

    /// Creates a validation rule from its structural form.
    ///
    /// ## Overview
    /// Use this initializer to build custom rule compositions that are not
    /// covered by the convenience members.
    ///
    /// - Parameter kind: The structural form of the rule.
    public init(kind: Kind) {
        self.kind = kind
    }

    /// The rendered validation-rule expression.
    ///
    /// ## Overview
    /// This description is used by tests and macro code to preserve a stable
    /// source representation for generated Vapor validators.
    public var description: String {
        describe(self, in: .root)
    }

    private enum DescriptionContext: Equatable {
        case root
        case unary
        case binary
    }

    private func describe(_ rule: ValidationRule, in context: DescriptionContext) -> String {
        switch rule.kind {
        case let .member(name):
            return ".\(name)"
        case let .call(name, arguments):
            let renderedArguments = arguments.map(\.description).joined(separator: ", ")
            return ".\(name)(\(renderedArguments))"
        case let .not(inner):
            let renderedInner = describe(inner, in: .unary)
            return "!\(renderedInner)"
        case let .and(lhs, rhs):
            let rendered = "\(describe(lhs, in: .binary)) && \(describe(rhs, in: .binary))"
            return context == .binary ? "(\(rendered))" : rendered
        case let .or(lhs, rhs):
            let rendered = "\(describe(lhs, in: .binary)) || \(describe(rhs, in: .binary))"
            return context == .binary ? "(\(rendered))" : rendered
        }
    }

    /// A rule that accepts ASCII content.
    ///
    /// ## Overview
    /// Renders Vapor's `.ascii` validator.
    public static var ascii: Self { .member("ascii") }

    /// A rule that accepts alphanumeric content.
    ///
    /// ## Overview
    /// Renders Vapor's `.alphanumeric` validator.
    public static var alphanumeric: Self { .member("alphanumeric") }

    /// A rule that accepts email addresses.
    ///
    /// ## Overview
    /// Renders Vapor's `.email` validator.
    public static var email: Self { .member("email") }

    /// A rule that accepts empty values.
    ///
    /// ## Overview
    /// Renders Vapor's `.empty` validator.
    public static var empty: Self { .member("empty") }

    /// A rule that accepts URLs.
    ///
    /// ## Overview
    /// Renders Vapor's `.url` validator.
    public static var url: Self { .member("url") }

    /// A rule that accepts nil values.
    ///
    /// ## Overview
    /// Renders Vapor's `.nil` validator.
    public static var `nil`: Self { .member("nil") }

    /// Creates a character-set validation rule.
    ///
    /// ## Overview
    /// Renders Vapor's `.characterSet(...)` validator with the supplied
    /// Foundation character set.
    ///
    /// - Parameter set: The accepted character set.
    /// - Returns: A validation rule that renders a character-set validator.
    public static func characterSet(_ set: CharacterSet) -> Self {
        .call("characterSet", arguments: [Argument(String(describing: set))])
    }

    /// Creates a count validation rule.
    ///
    /// ## Overview
    /// Renders Vapor's `.count(...)` validator for integer collection or string
    /// lengths.
    ///
    /// - Parameter bounds: The accepted count bounds.
    /// - Returns: A validation rule that renders a count validator.
    public static func count(_ bounds: some RangeExpression<Int>) -> Self {
        .call("count", arguments: [Argument(renderRangeExpression(bounds))])
    }

    /// Creates a comparable range validation rule.
    ///
    /// ## Overview
    /// Renders Vapor's `.range(...)` validator for comparable and codable
    /// values.
    ///
    /// - Parameter bounds: The accepted value bounds.
    /// - Returns: A validation rule that renders a range validator.
    public static func range<T>(_ bounds: some RangeExpression<T>) -> Self where T: Comparable & Codable & Sendable {
        .call("range", arguments: [Argument(renderRangeExpression(bounds))])
    }

    /// Creates a string membership validation rule.
    ///
    /// ## Overview
    /// Renders Vapor's `.in(...)` validator for accepted string values.
    ///
    /// - Parameter values: The accepted string values.
    /// - Returns: A validation rule that renders a string membership validator.
    public static func `in`(_ values: String...) -> Self {
        .call("in", arguments: values.map { Argument(String(reflecting: $0)) })
    }

    /// Creates an integer membership validation rule.
    ///
    /// ## Overview
    /// Renders Vapor's `.in(...)` validator for accepted integer values.
    ///
    /// - Parameter values: The accepted integer values.
    /// - Returns: A validation rule that renders an integer membership validator.
    public static func `in`(_ values: Int...) -> Self {
        .call("in", arguments: values.map { Argument(String($0)) })
    }
}

/// Negates a validation rule.
///
/// ## Overview
/// Use `!` to render Vapor's rule negation for a `ValidationRule`.
///
/// - Parameter rule: The rule to negate.
/// - Returns: A validation rule that renders the negated expression.
public prefix func ! (rule: ValidationRule) -> ValidationRule {
    .init(kind: .not(rule))
}

/// Combines two validation rules with logical AND.
///
/// ## Overview
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
/// ## Overview
/// Use `||` to accept values that satisfy either validation rule.
///
/// - Parameters:
///   - lhs: The left-hand validation rule.
///   - rhs: The right-hand validation rule.
/// - Returns: A validation rule that renders the disjunction.
public func || (lhs: ValidationRule, rhs: ValidationRule) -> ValidationRule {
    .init(kind: .or(lhs, rhs))
}

private extension ValidationRule {
    private static func member(_ name: String) -> Self {
        .init(kind: .member(name))
    }

    private static func call(_ name: String, arguments: [Argument]) -> Self {
        .init(kind: .call(name: name, arguments: arguments))
    }

    private static func renderRangeExpression<T: Comparable>(_ bounds: some RangeExpression<T>) -> String {
        let opaqueBounds = bounds as Any

        if let range = opaqueBounds as? ClosedRange<T> {
            return "\(String(describing: range.lowerBound))...\(String(describing: range.upperBound))"
        }

        if let range = opaqueBounds as? Range<T> {
            return "\(String(describing: range.lowerBound))..<\(String(describing: range.upperBound))"
        }

        if let range = opaqueBounds as? PartialRangeFrom<T> {
            return "\(String(describing: range.lowerBound))..."
        }

        if let range = opaqueBounds as? PartialRangeThrough<T> {
            return "...\(String(describing: range.upperBound))"
        }

        if let range = opaqueBounds as? PartialRangeUpTo<T> {
            return "..<\(String(describing: range.upperBound))"
        }

        return String(describing: bounds)
    }
}
