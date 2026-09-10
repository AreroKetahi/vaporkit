# Migrating from Vapor Validation

Replace a handwritten `Validatable` implementation with property constraints.

## Overview

Move each `validations.add` call to the property it names, preserving the rule,
`required` value, and custom failure message.

@Row {
    @Column {
        ```swift
        // Vapor
        struct Signup: Content, Validatable {
            var email: String

            static func validations(_ validations: inout Validations) {
                validations.add(
                    "email",
                    as: String.self,
                    is: .email,
                    customFailureDescription: "Invalid email."
                )
            }
        }
        ```
    }
    @Column {
        ```swift
        // VaporKit
        @ValidatableModel
        struct Signup: Content {
            @Constraint(.email, message: "Invalid email.")
            var email: String
        }
        ```
    }
}

The common Vapor rules map directly to ``ValidationRule`` members, and boolean
expressions keep the same `&&`, `||`, and `!` shape. Use
``Constraint(validating:message:with:)`` for a custom validator closure.

After every `validations.add` call has a matching property constraint, remove
the handwritten method and explicit `Validatable` conformance. Rebuild to
confirm that every stored property type and rule expression is supported.

See <doc:BuildValidationSystem> for optional fields, custom messages, and custom
predicates.

## Topics

### Migration APIs

- ``ValidatableModel()``
- ``Constraint(_:required:message:)``
- ``Constraint(validating:message:with:)``
