# Adding Model Validation

Generate Vapor validation from constraints declared beside model properties.

## Overview

Apply ``ValidatableModel()`` to a model and add a constraint to each property
that Vapor should validate:

```swift
@ValidatableModel
struct CreateUserRequest: Content {
    @Constraint(.alphanumeric && .count(3...32))
    var username: String

    @Constraint(.email, message: "Enter a valid email address.")
    var email: String

    @Constraint(.count(8...), required: false)
    var password: String?
}
```

VaporKit generates the native `Validatable` conformance and
`validations(_:)` implementation. Use the same model with Vapor's normal
validation API.

### Compose Rules

Build expressions from ``ValidationRule`` members using `&&`, `||`, and `!`.
The symbol page lists the built-in rules and their arguments.

Use ``Constraint(validating:message:with:)`` only when built-in rules can't
express the requirement:

```swift
@Constraint(validating: String.self, message: "Name is reserved.") { name in
    !["admin", "root"].contains(name.lowercased())
}
var username: String
```

For a field-by-field conversion from handwritten Vapor validation, see
<doc:MigratingFromVaporValidation>.

## Topics

### Validation APIs

- ``ValidatableModel()``
- ``Constraint(_:required:message:)``
- ``Constraint(validating:message:with:)``
- ``ValidationRule``
