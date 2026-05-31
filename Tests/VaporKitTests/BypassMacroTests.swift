import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import MacroTesting
import Testing

@Suite(.macros(testMacros))
struct BypassMacroTests {
    @Test func expandsWrappedExpression() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            let a = #Bypass { someValue.createValue() }
            """
        } expansion: {
            """
            let a = someValue.createValue()
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func expandsWrappedClosureArgument() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            let a = #Bypass({ someValue.createValue() })
            """
        } expansion: {
            """
            let a = someValue.createValue()
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func rejectsMissingTrailingClosure() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            let a = #Bypass()
            """
        } diagnostics: {
            """
            let a = #Bypass()
                    ┬────────
                    ╰─ 🛑 #Bypass requires a trailing closure.
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func rejectsMultipleStatements() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            let a = #Bypass {
                let value = someValue.createValue()
                value
            }
            """
        } diagnostics: {
            """
            let a = #Bypass {
                    ╰─ 🛑 #Bypass only supports a single expression in its closure body.
                let value = someValue.createValue()
                value
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }
}
