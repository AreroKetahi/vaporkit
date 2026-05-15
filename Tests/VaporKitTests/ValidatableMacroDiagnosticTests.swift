import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class ValidatableMacroDiagnosticTests: XCTestCase {
    func testValidatableModelRequiresStructOrClass() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @ValidatableModel
            enum CreateUser {
                case ready
            }
            """,
            expandedSource: """
            enum CreateUser {
                case ready
            }

            extension CreateUser: Vapor.Validatable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@ValidatableModel can only be attached to a struct or class.",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testConstraintRequiresExplicitType() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.email)
                var email = ""
            }
            """,
            expandedSource: """
            struct CreateUser {
                var email = ""

                static func validations(_ validations: inout Vapor.Validations) {

                }
            }

            extension CreateUser: Vapor.Validatable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Constraint properties must declare an explicit type.",
                    line: 3,
                    column: 5
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testConstraintRequiresStoredProperty() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.email)
                var email: String { "value" }
            }
            """,
            expandedSource: """
            struct CreateUser {
                var email: String { "value" }

                static func validations(_ validations: inout Vapor.Validations) {

                }
            }

            extension CreateUser: Vapor.Validatable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Constraint can only be applied to a stored property.",
                    line: 3,
                    column: 5
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testConstraintRequiresSingleBinding() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.email)
                var primary, secondary: String
            }
            """,
            expandedSource: """
            struct CreateUser {
                var primary, secondary: String

                static func validations(_ validations: inout Vapor.Validations) {

                }
            }

            extension CreateUser: Vapor.Validatable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "peer macro can only be applied to a single variable",
                    line: 3,
                    column: 5
                ),
                DiagnosticSpec(
                    message: "@Constraint properties must declare exactly one stored property.",
                    line: 3,
                    column: 5
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testConstraintRequiresRule() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint()
                var email: String
            }
            """,
            expandedSource: """
            struct CreateUser {
                var email: String

                static func validations(_ validations: inout Vapor.Validations) {

                }
            }

            extension CreateUser: Vapor.Validatable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Constraint requires a validation rule as its first argument.",
                    line: 3,
                    column: 5
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testConstraintMessageMustBeLiteral() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.email, message: reason)
                var email: String
            }
            """,
            expandedSource: """
            struct CreateUser {
                var email: String

                static func validations(_ validations: inout Vapor.Validations) {

                }
            }

            extension CreateUser: Vapor.Validatable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Constraint message must be a string literal or nil.",
                    line: 3,
                    column: 34
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testRejectsExistingValidationsMethod() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @ValidatableModel
            struct CreateUser {
                static func validations(_ validations: inout Vapor.Validations) {}
            }
            """,
            expandedSource: """
            struct CreateUser {
                static func validations(_ validations: inout Vapor.Validations) {}
            }

            extension CreateUser: Vapor.Validatable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@ValidatableModel cannot be applied to a type that already declares static func validations(_:).",
                    line: 3,
                    column: 5
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testRejectsRuleThatDoesNotMatchPropertyType() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.email)
                var age: Int
            }
            """,
            expandedSource: """
            struct CreateUser {
                var age: Int

                static func validations(_ validations: inout Vapor.Validations) {

                }
            }

            extension CreateUser: Vapor.Validatable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Constraint rule is not supported for this property type.",
                    line: 3,
                    column: 17
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testRejectsUnknownRule() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.totallyMadeUp)
                var email: String
            }
            """,
            expandedSource: """
            struct CreateUser {
                var email: String

                static func validations(_ validations: inout Vapor.Validations) {

                }
            }

            extension CreateUser: Vapor.Validatable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Constraint rule is not supported for this property type.",
                    line: 3,
                    column: 17
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testRejectsCustomConstraintTypeMismatch() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(validating: String.self, with: { value in
                    !value.isEmpty
                })
                var age: Int
            }
            """,
            expandedSource: """
            struct CreateUser {
                var age: Int

                static func validations(_ validations: inout Vapor.Validations) {

                }
            }

            extension CreateUser: Vapor.Validatable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Constraint(validating:with:) type must match the property type.",
                    line: 3,
                    column: 29
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testRejectsCustomConstraintWithoutClosure() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(validating: String.self)
                var slug: String
            }
            """,
            expandedSource: """
            struct CreateUser {
                var slug: String

                static func validations(_ validations: inout Vapor.Validations) {

                }
            }

            extension CreateUser: Vapor.Validatable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Constraint(validating:with:) requires a closure passed with the 'with' argument.",
                    line: 3,
                    column: 5
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testRejectsCustomConstraintWithNonLiteralMessage() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(validating: String.self, message: reason, with: { value in
                    !value.isEmpty
                })
                var slug: String
            }
            """,
            expandedSource: """
            struct CreateUser {
                var slug: String

                static func validations(_ validations: inout Vapor.Validations) {

                }
            }

            extension CreateUser: Vapor.Validatable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Constraint message must be a string literal or nil.",
                    line: 3,
                    column: 51
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
