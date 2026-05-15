import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class RouterMacroDiagnosticTests: XCTestCase {
    func testRequiresTrailingClosure() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @Router
            struct MyRoute {
                #Get("test", action: { req in
                    return "ok"
                })
            }
            """,
            expandedSource: """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {

                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Route macros only support trailing closures.",
                    line: 3,
                    column: 5,
                    fixIts: [FixItSpec(message: "Move closure to trailing closure")]
                )
            ],
            macros: testMacros,
            fixedSource: """
            @Router
            struct MyRoute {
                #Get("test"){ req in
                    return "ok"
                }
            }
            """
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testRejectsClosureReferenceArgument() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @Router
            struct MyRoute {
                #Get("test", action: handler)
            }
            """,
            expandedSource: """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {

                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Route macros do not accept closure references as arguments. Use a trailing closure and call the handler explicitly.",
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

    func testRejectsMissingRequiredPathParameterInFreestandingRoute() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @Router
            struct MyRoute {
                #Get("test/:id") { req in
                    let slug = try req.parameters.require("slug")
                    return slug
                }
            }
            """,
            expandedSource: """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "test", ":id", use: ___macro_local_12RouteHandlerfMu_)
                }

                func ___macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        let slug = try req.parameters.require("slug")
                        return slug
                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Required path parameter is not declared in this route URL.",
                    line: 4,
                    column: 24
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testIgnoresNestedClosureParameterAccess() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @Router
            struct MyRoute {
                #Get("test/:id") { req in
                    let loader = {
                        let req = ServiceRequest()
                        return try req.parameters.require("slug")
                    }
                    return try loader()
                }
            }
            """,
            expandedSource: """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "test", ":id", use: ___macro_local_12RouteHandlerfMu_)
                }

                func ___macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        let loader = {
                            let req = ServiceRequest()
                            return try req.parameters.require("slug")
                        }
                        return try loader()
                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testRejectsMissingPathParameterAccessWithoutTry() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @Router
            struct MyRoute {
                #Get("test/:id") { req in
                    let slug = req.parameters.get("slug")
                    let nested = wrap(req.parameters.get("nested"))
                    return slug ?? nested
                }
            }
            """,
            expandedSource: """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "test", ":id", use: ___macro_local_12RouteHandlerfMu_)
                }

                func ___macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        let slug = req.parameters.get("slug")
                        let nested = wrap(req.parameters.get("nested"))
                        return slug ?? nested
                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Required path parameter is not declared in this route URL.",
                    line: 4,
                    column: 20
                ),
                DiagnosticSpec(
                    message: "Required path parameter is not declared in this route URL.",
                    line: 5,
                    column: 27
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testIgnoresBypassedParameterAccess() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @Router
            struct MyRoute {
                #Get("test/:id") { req in
                    let slug = #Bypass { try req.parameters.require("slug") }
                    return slug
                }
            }
            """,
            expandedSource: """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "test", ":id", use: ___macro_local_12RouteHandlerfMu_)
                }

                func ___macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        let slug = try req.parameters.require("slug")
                        return slug
                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testWarnsForDynamicPathParameterAccess() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @Router
            struct MyRoute {
                #Get("test/:id") { req in
                    let key = "id"
                    let id = req.parameters.get(key)
                    return id
                }
            }
            """,
            expandedSource: """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "test", ":id", use: ___macro_local_12RouteHandlerfMu_)
                }

                func ___macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        let key = "id"
                        let id = req.parameters.get(key)
                        return id
                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Getting a route parameter from a variable is unsafe for static checking. Use a string literal, or wrap the expression in #Bypass to silence this warning.",
                    line: 5,
                    column: 18,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testDowngradesParameterErrorsAndSuppressesWarnings() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @DisableParameterCheck(as: .warning)
            @Router
            struct MyRoute {
                #Get("test/:id") { req in
                    let key = "slug"
                    let dynamic = req.parameters.get(key)
                    let slug = try req.parameters.require("slug")
                    return dynamic ?? slug
                }
            }
            """,
            expandedSource: """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "test", ":id", use: ___macro_local_12RouteHandlerfMu_)
                }

                func ___macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        let key = "slug"
                        let dynamic = req.parameters.get(key)
                        let slug = try req.parameters.require("slug")
                        return dynamic ?? slug
                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Required path parameter is not declared in this route URL.",
                    line: 7,
                    column: 24,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testBypassWarningModeDowngradesOnlyWrappedErrors() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @Router
            struct MyRoute {
                #Get("test/:id") { req in
                    let key = "slug"
                    let slug = #Bypass(as: .warning) { try req.parameters.require("slug") }
                    let dynamic = #Bypass(as: .warning) { req.parameters.get(key) }
                    return dynamic ?? slug
                }
            }
            """,
            expandedSource: """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "test", ":id", use: ___macro_local_12RouteHandlerfMu_)
                }

                func ___macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        let key = "slug"
                        let slug = try req.parameters.require("slug")
                        let dynamic = req.parameters.get(key)
                        return dynamic ?? slug
                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Required path parameter is not declared in this route URL.",
                    line: 5,
                    column: 48,
                    severity: .warning
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testWebSocketRequiresTrailingClosure() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @Router
            struct MyRoute {
                #WebSocket("chat", action: {})
            }
            """,
            expandedSource: """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {

                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#WebSocket only supports trailing closures.",
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

    func testWebSocketRejectsNonEventStatements() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @Router
            struct MyRoute {
                #WebSocket("chat") {
                    let value = 1
                }
            }
            """,
            expandedSource: """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.webSocket("chat", onUpgrade: ___macro_local_16WebSocketHandlerfMu_)
                }

                func ___macro_local_16WebSocketHandlerfMu_(req: Vapor.Request, ws: Vapor.WebSocket) async {
                    let _ = req

                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#WebSocket bodies may only contain websocket event macros.",
                    line: 4,
                    column: 9
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testWebSocketRejectsInvalidEventSignatures() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @Router
            struct MyRoute {
                #WebSocket("chat") {
                    #OnText { text in
                        print(text)
                    }

                    #OnClose { ws in
                        print(ws)
                    }
                }
            }
            """,
            expandedSource: """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.webSocket("chat", onUpgrade: ___macro_local_16WebSocketHandlerfMu_)
                }

                func ___macro_local_16WebSocketHandlerfMu_(req: Vapor.Request, ws: Vapor.WebSocket) async {
                    let _ = req

                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#OnText and #OnBinary handlers must accept exactly two parameters.",
                    line: 4,
                    column: 9
                ),
                DiagnosticSpec(
                    message: "#OnClose handlers must not declare parameters.",
                    line: 8,
                    column: 9
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testWebSocketRejectsUnexpectedAdditionalTrailingClosureLabel() throws {
        #if canImport(VaporKitMacros)
        assertMacroExpansion(
            """
            @Router
            struct MyRoute {
                #WebSocket("chat") {
                    ["X-Test": "1"]
                } upgraded: {
                    #OnClose {
                        print("closed")
                    }
                }
            }
            """,
            expandedSource: """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.webSocket("chat", onUpgrade: ___macro_local_16WebSocketHandlerfMu_)
                }

                func ___macro_local_16WebSocketHandlerfMu_(req: Vapor.Request, ws: Vapor.WebSocket) async {
                    let _ = req

                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "#WebSocket only supports an additional trailing closure labeled didUpgrade:.",
                    line: 5,
                    column: 7
                ),
                DiagnosticSpec(
                    message: "#WebSocket bodies may only contain websocket event macros.",
                    line: 4,
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
