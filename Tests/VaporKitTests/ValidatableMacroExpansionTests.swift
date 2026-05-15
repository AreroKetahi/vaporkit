import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Testing
import MacroTesting

@Suite(.macros(testMacros))
struct ValidatableMacroExpansionTests {
    @Test func generatesValidationsFromConstraintProperties() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
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
            """
        } expansion: {
            """
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
            """
        }
        #else
        try Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func skipsNilMessageArgument() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @ValidatableModel
            struct CreateUser {
                @Constraint(.email, message: nil)
                var email: String
            }
            """
        } expansion: {
            """
            struct CreateUser {
                var email: String
            
                static func validations(_ validations: inout Vapor.Validations) {
                    let __macro_local_10validationfMu_: Vapor.Validator<String> = .email
                    validations.add("email", as: String.self, is: __macro_local_10validationfMu_)
                }
            }
            
            extension CreateUser: Vapor.Validatable {
            }
            """
        }
        #else
        try Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }
}
