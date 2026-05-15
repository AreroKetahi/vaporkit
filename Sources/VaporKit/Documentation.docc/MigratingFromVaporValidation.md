# Migrating From Vapor Validation

Move handwritten Vapor validation code to VaporKit validation macros.

## Overview

Legacy Vapor validation code usually places all validation logic in
`validations(_:)`. VaporKit keeps the validation intent next to each property
and generates the `Validatable` implementation.

## Mark the Model

Replace a manual `Validatable` conformance with ``ValidatableModel()``.

@Row {
    @Column {
        ```swift
        // Vapor

        struct CreateUserRequest: Content, Validatable {
            var username: String
            var email: String

            static func validations(_ validations: inout Validations) {
                validations.add("username", as: String.self, is: .alphanumeric && .count(3...32))
                validations.add("email", as: String.self, is: .email)
            }
        }
        ```
    }
    @Column {
        ```swift
        // VaporKit

        @ValidatableModel
        struct CreateUserRequest: Content {
            @Constraint(.alphanumeric && .count(3...32))
            var username: String

            @Constraint(.email)
            var email: String
        }
        ```
    }
}

## Move Each Validation to Its Property

For each `validations.add(...)` call, attach ``Constraint(_:required:message:)``
to the matching stored property.

@Row {
    @Column {
        ```swift
        validations.add("age", as: Int.self, is: .range(13...))
        ```
    }
    @Column {
        ```swift
        @Constraint(.range(13...))
        var age: Int
        ```
    }
}

If the old validation used `required: false`, keep that setting on the macro.

@Row {
    @Column {
        ```swift
        validations.add(
            "nickname",
            as: String.self,
            is: .count(1...40),
            required: false
        )
        ```
    }
    @Column {
        ```swift
        @Constraint(.count(1...40), required: false)
        var nickname: String?
        ```
    }
}

## Preserve Custom Messages

Move custom validation messages to the `message` argument.

@Row {
    @Column {
        ```swift
        validations.add(
            "email",
            as: String.self,
            is: .email,
            customFailureDescription: "Email address is invalid."
        )
        ```
    }
    @Column {
        ```swift
        @Constraint(.email, message: "Email address is invalid.")
        var email: String
        ```
    }
}

## Migrate Custom Validators

When legacy code uses a custom validator closure, use
``Constraint(validating:message:with:)``.

@Row {
    @Column {
        ```swift
        validations.add(
            "username",
            as: String.self,
            is: .custom("Name is reserved.") { name in
                !["admin", "root"].contains(name.lowercased())
            }
        )
        ```
    }
    @Column {
        ```swift
        @Constraint(validating: String.self, message: "Name is reserved.") { name in
            !["admin", "root"].contains(name.lowercased())
        }
        var username: String
        ```
    }
}

## Check Rule Support

Most common Vapor validators map directly to ``ValidationRule`` helpers:

- `.ascii` maps to ``ValidationRule/ascii``
- `.alphanumeric` maps to ``ValidationRule/alphanumeric``
- `.email` maps to ``ValidationRule/email``
- `.empty` maps to ``ValidationRule/empty``
- `.url` maps to ``ValidationRule/url``
- `.nil` maps to ``ValidationRule/nil``
- `.count(...)` maps to ``ValidationRule/count(_:)``
- `.range(...)` maps to ``ValidationRule/range(_:)``
- `.in(...)` maps to ``ValidationRule/in(_:)-(Int...)`` or ``ValidationRule/in(_:)-(String...)``
- `.characterSet(...)` maps to ``ValidationRule/characterSet(_:)``

Boolean composition keeps the same shape:

```swift
@Constraint(.email || .empty)
var recoveryEmail: String

@Constraint(.alphanumeric && .count(3...32))
var username: String

@Constraint(!.empty)
var displayName: String
```

## Remove Handwritten Validation Code

After every property has a constraint, remove the manual `validations(_:)`
method and remove `Validatable` from the type declaration. Rebuild the project
so the macro can generate the replacement conformance.

## Topics

### Migration Targets

- ``ValidatableModel()``
- ``Constraint(_:required:message:)``
- ``Constraint(validating:message:with:)``

## See Also

- <doc:BuildValidationSystem>
