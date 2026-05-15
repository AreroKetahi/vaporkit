//
//  ValidationRule.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 27/03/2026
//

import Foundation

/// Describes a Vapor validation rule expression.
///
/// `ValidationRule` is a syntax-level representation used by ``Constraint(_:required:message:)``.
/// Compose rules with the provided static members, factory methods, and boolean
/// operators to generate Vapor validation expressions.
public struct ValidationRule: Sendable, Equatable, Hashable, CustomStringConvertible {
    /// Describes a rendered validation-rule argument.
    ///
    /// `Argument` stores the source representation for an argument passed to a
    /// validation rule factory, such as `.count(1...10)`.
    public struct Argument: Sendable, Equatable, Hashable, CustomStringConvertible {
        /// The rendered source description.
        ///
        /// This value is emitted into the generated validation expression.
        public let description: String

        /// Creates a rendered validation-rule argument.
        ///
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
    /// `Kind` stores either a named Vapor validator, a validator call, or a
    /// boolean composition of other validation rules.
    public indirect enum Kind: Sendable, Equatable, Hashable {
        /// A named validator member.
        ///
        /// Represents validators such as `.email` or `.alphanumeric`.
        case member(String)

        /// A validator call with rendered arguments.
        ///
        /// Represents validators such as `.count(1...10)` or `.in("a", "b")`.
        case call(name: String, arguments: [Argument])

        /// The negation of another validation rule.
        ///
        /// Represents `!rule` in a generated validation expression.
        case not(ValidationRule)

        /// A conjunction of two validation rules.
        ///
        /// Represents `lhs && rhs` in a generated validation expression.
        case and(ValidationRule, ValidationRule)

        /// A disjunction of two validation rules.
        ///
        /// Represents `lhs || rhs` in a generated validation expression.
        case or(ValidationRule, ValidationRule)
    }

    /// The structural form of this rule.
    ///
    /// The macro renders `kind` into the Vapor validation expression used by
    /// generated `validations(_:)`.
    public let kind: Kind

    /// Creates a validation rule from its structural form.
    ///
    /// Use this initializer to build custom rule compositions that are not
    /// covered by the convenience members.
    ///
    /// - Parameter kind: The structural form of the rule.
    public init(kind: Kind) {
        self.kind = kind
    }

    /// The rendered validation-rule expression.
    ///
    /// This description is used by tests and macro code to preserve a stable
    /// source representation for generated Vapor validators.
    public var description: String {
        _describe(self, in: .root)
    }

    private enum _DescriptionContext: Equatable {
        case root
        case unary
        case binary
    }

    private func _describe(_ rule: ValidationRule, in context: _DescriptionContext) -> String {
        switch rule.kind {
        case let .member(name):
            return ".\(name)"
        case let .call(name, arguments):
            let renderedArguments = arguments.map(\.description).joined(separator: ", ")
            return ".\(name)(\(renderedArguments))"
        case let .not(inner):
            let renderedInner = _describe(inner, in: .unary)
            return "!\(renderedInner)"
        case let .and(lhs, rhs):
            let rendered = "\(_describe(lhs, in: .binary)) && \(_describe(rhs, in: .binary))"
            return context == .binary ? "(\(rendered))" : rendered
        case let .or(lhs, rhs):
            let rendered = "\(_describe(lhs, in: .binary)) || \(_describe(rhs, in: .binary))"
            return context == .binary ? "(\(rendered))" : rendered
        }
    }

    /// A rule that accepts ASCII content.
    ///
    /// Renders Vapor's `.ascii` validator.
    public static var ascii: Self { ._member("ascii") }

    /// A rule that accepts alphanumeric content.
    ///
    /// Renders Vapor's `.alphanumeric` validator.
    public static var alphanumeric: Self { ._member("alphanumeric") }

    /// A rule that accepts email addresses.
    ///
    /// Renders Vapor's `.email` validator.
    public static var email: Self { ._member("email") }

    /// A rule that accepts empty values.
    ///
    /// Renders Vapor's `.empty` validator.
    public static var empty: Self { ._member("empty") }

    /// A rule that accepts URLs.
    ///
    /// Renders Vapor's `.url` validator.
    public static var url: Self { ._member("url") }

    /// A rule that accepts nil values.
    ///
    /// Renders Vapor's `.nil` validator.
    public static var `nil`: Self { ._member("nil") }

    /// Creates a character-set validation rule.
    ///
    /// Renders Vapor's `.characterSet(...)` validator with the supplied
    /// Foundation character set.
    ///
    /// - Parameter set: The accepted character set.
    /// - Returns: A validation rule that renders a character-set validator.
    public static func characterSet(_ set: CharacterSet) -> Self {
        ._call("characterSet", arguments: [Argument(String(describing: set))])
    }

    /// Creates a count validation rule.
    ///
    /// Renders Vapor's `.count(...)` validator for integer collection or string
    /// lengths.
    ///
    /// - Parameter bounds: The accepted count bounds.
    /// - Returns: A validation rule that renders a count validator.
    public static func count(_ bounds: some RangeExpression<Int>) -> Self {
        ._call("count", arguments: [Argument(_renderRangeExpression(bounds))])
    }

    /// Creates a comparable range validation rule.
    ///
    /// Renders Vapor's `.range(...)` validator for comparable and codable
    /// values.
    ///
    /// - Parameter bounds: The accepted value bounds.
    /// - Returns: A validation rule that renders a range validator.
    public static func range<T>(_ bounds: some RangeExpression<T>) -> Self where T: Comparable & Codable & Sendable {
        ._call("range", arguments: [Argument(_renderRangeExpression(bounds))])
    }

    /// Creates a string membership validation rule.
    ///
    /// Renders Vapor's `.in(...)` validator for accepted string values.
    ///
    /// - Parameter values: The accepted string values.
    /// - Returns: A validation rule that renders a string membership validator.
    public static func `in`(_ values: String...) -> Self {
        ._call("in", arguments: values.map { Argument(String(reflecting: $0)) })
    }

    /// Creates an integer membership validation rule.
    ///
    /// Renders Vapor's `.in(...)` validator for accepted integer values.
    ///
    /// - Parameter values: The accepted integer values.
    /// - Returns: A validation rule that renders an integer membership validator.
    public static func `in`(_ values: Int...) -> Self {
        ._call("in", arguments: values.map { Argument(String($0)) })
    }
}

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

private extension ValidationRule {
    private static func _member(_ name: String) -> Self {
        .init(kind: .member(name))
    }

    private static func _call(_ name: String, arguments: [Argument]) -> Self {
        .init(kind: .call(name: name, arguments: arguments))
    }

    private static func _renderRangeExpression<T: Comparable>(_ bounds: some RangeExpression<T>) -> String {
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
