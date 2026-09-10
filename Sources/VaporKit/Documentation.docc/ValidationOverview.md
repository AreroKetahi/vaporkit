# Validation

Generate native Vapor validation rules from declarations on a model.

## Overview

Apply ``ValidatableModel()`` to a model and annotate its validated properties
with `@Constraint`. VaporKit generates the Vapor `Validatable` implementation at
compile time, so validation has no additional runtime abstraction.

### Declaring Constraints

Use a validation expression for Vapor's built-in rules, or provide a custom
predicate when a field needs domain-specific validation.

```swift
@ValidatableModel
struct SignupRequest: Content {
    @Constraint(.alphanumeric && .count(3...32))
    var username: String

    @Constraint(.email, message: "Enter a valid email address.")
    var email: String

    @Constraint(.count(8...), required: false)
    var password: String?
}
```

Use the generated conformance through Vapor's normal validation API:

```swift
try SignupRequest.validate(content: request)
let signup = try request.content.decode(SignupRequest.self)
```

### Composing Rules

``ValidationRule`` represents a rule expression. Combine rules with `&&` and
`||` to build the constraint required by a property.

Use a predicate when built-in rules can't express the requirement:

```swift
@Constraint(validating: String.self, message: "Name is reserved.") { name in
    !["admin", "root"].contains(name.lowercased())
}
var username: String
```

### Migrating from Vapor Validation

Follow <doc:MigratingFromVaporValidation> to move an existing `Validatable`
implementation to generated constraints one model at a time.

## Topics

### Declaring Validation

- ``ValidatableModel()``
- ``Constraint(_:required:message:)``
- ``Constraint(validating:message:with:)``

### Validation Rules

- ``ValidationRule``
- ``ValidationRule/Argument``
- ``ValidationRule/Kind``

### Articles

- <doc:BuildValidationSystem>
- <doc:MigratingFromVaporValidation>
