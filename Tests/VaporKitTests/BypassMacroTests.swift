import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class BypassMacroTests: XCTestCase {
    func testExpandsWrappedExpression() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            let a = #Bypass { someValue.createValue() }
            """,
            expandedSource: """
            let a = someValue.createValue()
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testRejectsMissingTrailingClosure() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            let a = #Bypass()
            """,
            expandedSource: """
            let a = ()
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#Bypass requires a trailing closure.",
                    line: 1,
                    column: 9
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testRejectsMultipleStatements() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            let a = #Bypass {
                let value = someValue.createValue()
                value
            }
            """,
            expandedSource: """
            let a = ()
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#Bypass only supports a single expression in its closure body.",
                    line: 1,
                    column: 9
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
