import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Testing
import MacroTesting

@Suite(.macros(testMacros))
struct ValidatableMacroDiagnosticTests {
    @Test func validatableModelRequiresStructOrClass() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @ValidatableModel
            enum CreateUser {
                case ready
            }
            """
        } diagnostics: {
            """
            @ValidatableModel
            ┬────────────────
            ╰─ 🛑 @ValidatableModel can only be attached to a struct or class.
            enum CreateUser {
                case ready
            }
            """
        }
        #else
        try Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func constraintRequiresExplicitType() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.email)
                var email = ""
            }
            """
        } diagnostics: {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.email)
                ╰─ 🛑 @Constraint properties must declare an explicit type.
                var email = ""
            }
            """
        }
        #else
        try Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func constraintRequiresStoredProperty() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.email)
                var email: String { "value" }
            }
            """
        } diagnostics: {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.email)
                ╰─ 🛑 @Constraint can only be applied to a stored property.
                var email: String { "value" }
            }
            """
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func constraintRequiresSingleBinding() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.email)
                var primary, secondary: String
            }
            """
        } diagnostics: {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.email)
                ┬──────────────────
                ├─ 🛑 peer macro can only be applied to a single variable
                ╰─ 🛑 @Constraint properties must declare exactly one stored property.
                var primary, secondary: String
            }
            """
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func constraintRequiresRule() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint()
                var email: String
            }
            """
        } diagnostics: {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint()
                ┬────────────
                ╰─ 🛑 @Constraint requires a validation rule as its first argument.
                var email: String
            }
            """
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func constraintMessageMustBeLiteral() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.email, message: reason)
                var email: String
            }
            """
        } diagnostics: {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.email, message: reason)
                                             ┬─────
                                             ╰─ 🛑 @Constraint message must be a string literal or nil.
                var email: String
            }
            """
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func rejectsExistingValidationsMethod() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @ValidatableModel
            struct CreateUser {
                static func validations(_ validations: inout Vapor.Validations) {}
            }
            """
        } diagnostics: {
            """
            @ValidatableModel
            struct CreateUser {
                static func validations(_ validations: inout Vapor.Validations) {}
                ┬─────────────────────────────────────────────────────────────────
                ╰─ 🛑 @ValidatableModel cannot be applied to a type that already declares static func validations(_:).
            }
            """
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func rejectsRuleThatDoesNotMatchPropertyType() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.email)
                var age: Int
            }
            """
        } diagnostics: {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.email)
                            ┬─────
                            ╰─ 🛑 @Constraint rule is not supported for this property type.
                var age: Int
            }
            """
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func rejectsUnknownRule() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.totallyMadeUp)
                var email: String
            }
            """
        } diagnostics: {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.totallyMadeUp)
                            ┬─────────────
                            ╰─ 🛑 @Constraint rule is not supported for this property type.
                var email: String
            }
            """
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func rejectsCustomConstraintTypeMismatch() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(validating: String.self, with: { value in
                    !value.isEmpty
                })
                var age: Int
            }
            """
        } diagnostics: {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(validating: String.self, with: { value in
                                        ┬──────────
                                        ╰─ 🛑 @Constraint(validating:with:) type must match the property type.
                    !value.isEmpty
                })
                var age: Int
            }
            """
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func rejectsCustomConstraintWithoutClosure() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(validating: String.self)
                var slug: String
            }
            """
        } diagnostics: {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(validating: String.self)
                ┬───────────────────────────────────
                ╰─ 🛑 @Constraint(validating:with:) requires a closure passed with the 'with' argument.
                var slug: String
            }
            """
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func rejectsCustomConstraintWithNonLiteralMessage() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(validating: String.self, message: reason, with: { value in
                    !value.isEmpty
                })
                var slug: String
            }
            """
        } diagnostics: {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(validating: String.self, message: reason, with: { value in
                                                              ┬─────
                                                              ╰─ 🛑 @Constraint message must be a string literal or nil.
                    !value.isEmpty
                })
                var slug: String
            }
            """
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
