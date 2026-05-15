import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class ValidatableMacroExpansionTests: XCTestCase {
    func testGeneratesValidationsFromConstraintProperties() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.email)
                var email: String

                @Constraint(.count(3...), message: "Too short")
                var nickname: String

                @Constraint(.range(18...))
                var age: Int?

                @Constraint(.ascii)
                @Constraint(.count(...32))
                var handle: String

                @Constraint(validating: String.self, message: "Slug must not be empty", with: { value in
                    !value.isEmpty
                })
                var slug: String
            }
            """,
            expandedSource: """
            struct CreateUser {
                var email: String
                var nickname: String
                var age: Int?
                var handle: String
                var slug: String

                static func validations(_ validations: inout Vapor.Validations) {
                    let __macro_local_10validationfMu_: Vapor.Validator<String> = .email
                    validations.add("email", as: String.self, is: __macro_local_10validationfMu_)
                    let __macro_local_10validationfMu0_: Vapor.Validator<String> = .count(3...)
                    validations.add("nickname", as: String.self, is: __macro_local_10validationfMu0_, customFailureDescription: "Too short")
                    let __macro_local_10validationfMu1_: Vapor.Validator<Int> = .range(18...)
                    validations.add("age", as: Int.self, is: __macro_local_10validationfMu1_, required: false)
                    let __macro_local_10validationfMu2_: Vapor.Validator<String> = .ascii
                    validations.add("handle", as: String.self, is: __macro_local_10validationfMu2_)
                    let __macro_local_10validationfMu3_: Vapor.Validator<String> = .count(...32)
                    validations.add("handle", as: String.self, is: __macro_local_10validationfMu3_)
                    let __macro_local_10validationfMu4_: Vapor.Validator<String> = .custom("Slug must not be empty", validationClosure: { value in
                        return ({ value in
                            !value.isEmpty
                        })(value)
                        })
                    validations.add("slug", as: String.self, is: __macro_local_10validationfMu4_)
                }
            }

            extension CreateUser: Vapor.Validatable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testSkipsNilMessageArgument() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.email, message: nil)
                var email: String
            }
            """,
            expandedSource: """
            struct CreateUser {
                var email: String

                static func validations(_ validations: inout Vapor.Validations) {
                    let __macro_local_10validationfMu_: Vapor.Validator<String> = .email
                    validations.add("email", as: String.self, is: __macro_local_10validationfMu_)
                }
            }

            extension CreateUser: Vapor.Validatable {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
