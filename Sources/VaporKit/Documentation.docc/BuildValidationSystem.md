# Build a Validation System

Use VaporKit validation macros to generate Vapor `Validatable` code from
property-level declarations.

## Overview

Vapor validation usually requires a type to conform to `Validatable` and
implement `validations(_:)` manually. VaporKit moves that repeated code to
macros: mark the model with ``ValidatableModel()`` and describe each validated
property with ``Constraint(_:required:message:)``.

## Create a Validatable Model

Attach ``ValidatableModel()`` to the model type.

```swift
@ValidatableModel
struct CreateUserRequest: Content {
    @Constraint(.alphanumeric && .count(3...32))
    var username: String

    @Constraint(.email)
    var email: String
}
```

The macro adds `Vapor.Validatable` conformance and generates
`validations(_:)` from the annotated properties.

## Add Basic Rules

Use ``ValidationRule`` static members for common Vapor validators.

```swift
@ValidatableModel
struct LoginRequest: Content {
    @Constraint(.email)
    var email: String

    @Constraint(.count(8...))
    var password: String
}
```

Available convenience rules include:

- ``ValidationRule/ascii``
- ``ValidationRule/alphanumeric``
- ``ValidationRule/email``
- ``ValidationRule/empty``
- ``ValidationRule/url``
- ``ValidationRule/nil``
- ``ValidationRule/count(_:)``
- ``ValidationRule/range(_:)``
- ``ValidationRule/in(_:)-(Int...)``
- ``ValidationRule/in(_:)-(String...)``
- ``ValidationRule/characterSet(_:)``

## Compose Rules

Combine rules with boolean operators.

```swift
@Constraint(.alphanumeric && .count(3...32))
var username: String

@Constraint(.email || .empty)
var recoveryEmail: String

@Constraint(!.empty)
var displayName: String
```

The operators ``!(_:)->ValidationRule``, ``&&(_:_:)->ValidationRule``, and 
``||(_:_:)->ValidationRule`` preserve the rule tree, so generated validation 
keeps the intended precedence.

## Configure Required Fields

Use `required` when a field can be absent but still needs validation when
present.

```swift
@ValidatableModel
struct PatchUserRequest: Content {
    @Constraint(.count(3...32), required: false)
    var username: String?
}
```

Use `message` to provide a custom validation failure message.

```swift
@Constraint(.email, message: "Email address is invalid.")
var email: String
```

## Add Custom Predicates

Use the custom ``Constraint(validating:message:with:)`` overload when a rule
cannot be expressed with Vapor's built-in validators.

```swift
@ValidatableModel
struct SignupRequest: Content {
    @Constraint(validating: String.self, message: "Name is reserved.") { name in
        !["admin", "root", "system"].contains(name.lowercased())
    }
    var username: String
}
```

The custom predicate receives the decoded property value and returns `true`
when the value is valid.

## Topics

### Validation Macros

- ``ValidatableModel()``
- ``Constraint(_:required:message:)``
- ``Constraint(validating:message:with:)``

### Validation Rules

- ``ValidationRule``
- ``ValidationRule/Argument``
- ``ValidationRule/Kind``
- ``!(_:)->ValidationRule``
- ``&&(_:_:)->ValidationRule``
- ``||(_:_:)->ValidationRule``
