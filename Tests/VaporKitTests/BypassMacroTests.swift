import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import MacroTesting
import Testing
import VaporKit

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

    @Test func expandsMultipleStatementsAsImmediatelyInvokedClosure() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            let a = #Bypass {
                let value = someValue.createValue()
                value
            }
            """
        } expansion: {
            """
            let a = {
                let value = someValue.createValue()
                value
            }()
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func expandsThrowingMultipleStatementsAsImmediatelyInvokedClosure() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            let a = try #Bypass {
                let value = try someValue.createValue()
                value
            }
            """
        } expansion: {
            """
            let a = try {
                let value = try someValue.createValue()
                value
            }()
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func expandsAsyncThrowingMultipleStatementsAsImmediatelyInvokedClosure() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            let a = try await #Bypass {
                let value = try await someValue.createValue()
                value
            }
            """
        } expansion: {
            """
            let a = try await {
                let value = try await someValue.createValue()
                value
            }()
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func publicBypassOverloadsCompileAndExecuteBlocks() async throws {
        #expect(Self.syncBlock(2) == 3)
        #expect(try Self.throwingBlock(3) == 4)
        #expect(await Self.asyncBlock(4) == 5)
        #expect(try await Self.asyncThrowingBlock(5) == 6)
    }

    private static func syncBlock(_ value: Int) -> Int {
        #Bypass {
            let next = value + 1
            return next
        }
    }

    private static func throwingBlock(_ value: Int) throws -> Int {
        try #Bypass {
            let next = try throwingIncrement(value)
            return next
        }
    }

    private static func asyncBlock(_ value: Int) async -> Int {
        await #Bypass {
            let next = await asyncIncrement(value)
            return next
        }
    }

    private static func asyncThrowingBlock(_ value: Int) async throws -> Int {
        try await #Bypass {
            let next = try await asyncThrowingIncrement(value)
            return next
        }
    }

    private static func throwingIncrement(_ value: Int) throws -> Int {
        value + 1
    }

    private static func asyncIncrement(_ value: Int) async -> Int {
        value + 1
    }

    private static func asyncThrowingIncrement(_ value: Int) async throws -> Int {
        value + 1
    }
}
