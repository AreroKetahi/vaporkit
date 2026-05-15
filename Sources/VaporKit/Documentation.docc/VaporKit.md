# ``VaporKit``

A collection of macros that simplify Vapor routing and validation.

## Overview

VaporKit is a macro-based library for reducing repetitive Vapor route
registration and validation boilerplate. It keeps generated code close to
Vapor's native APIs while letting application code focus on request handling
and model rules.

## Topics

### Essentials

- <doc:MigratingFromVaporRouting>
- <doc:MigratingFromVaporValidation>

### Compile-time Static Code Checking

- <doc:StaticRouteParameterChecking>
- ``StaticCheckSeverity``

### Route Collection

- <doc:CreateRouter>
- ``Router(_:)``

### Validation

- <doc:BuildValidationSystem>
- ``ValidatableModel()``
- ``ValidationRule``
