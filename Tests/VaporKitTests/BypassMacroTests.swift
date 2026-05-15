import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import MacroTesting
import XCTest

final class BypassMacroTests: XCTestCase {
    override func invokeTest() {
        #if canImport(VaporKitMacros)
        withMacroTesting(macros: testMacros) {
            super.invokeTest()
        }
        #else
        super.invokeTest()
        #endif
    }

    func testExpandsWrappedExpression() throws {
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
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testExpandsWrappedClosureArgument() throws {
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
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testRejectsMissingTrailingClosure() throws {
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
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testRejectsMultipleStatements() throws {
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
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
