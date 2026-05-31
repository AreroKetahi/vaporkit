import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import MacroTesting
import Testing

@Suite(.macros(testMacros))
struct RouterMacroDiagnosticTests {
    @Test func requiresTrailingClosure() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router
            struct MyRoute {
                #Get("test", action: { req in
                    return "ok"
                })
            }
            """
        } diagnostics: {
            """
            @Router
            struct MyRoute {
                #Get("test", action: { req in
                ╰─ 🛑 Route macros only support trailing closures.
                   ✏️ Move closure to trailing closure
                    return "ok"
                })
            }
            """
        } fixes: {
            """
            @Router
            struct MyRoute {
                #Get("test"){ req in
                    return "ok"
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "test", use: __macro_local_12RouteHandlerfMu_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        return "ok"
                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func rejectsClosureReferenceArgument() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router
            struct MyRoute {
                #Get("test", action: handler)
            }
            """
        } diagnostics: {
            """
            @Router
            struct MyRoute {
                #Get("test", action: handler)
                ┬────────────────────────────
                ╰─ 🛑 Route macros do not accept closure references as arguments. Use a trailing closure and call the handler explicitly.
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func rejectsMissingRequiredPathParameterInFreestandingRoute() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router
            struct MyRoute {
                #Get("test/:id") { req in
                    let slug = try req.parameters.require("slug")
                    return slug
                }
            }
            """
        } diagnostics: {
            """
            @Router
            struct MyRoute {
                #Get("test/:id") { req in
                    let slug = try req.parameters.require("slug")
                                   ┬─────────────────────────────
                                   ╰─ 🛑 Required path parameter is not declared in this route URL.
                    return slug
                }
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func ignoresNestedClosureParameterAccess() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
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
            """
        } expansion: {
            """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "test", ":id", use: __macro_local_12RouteHandlerfMu_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        let loader = {
                            let req = ServiceRequest()
                            return try req.parameters.require("slug")
                        }
                        return try loader()
                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func rejectsMissingPathParameterAccessWithoutTry() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router
            struct MyRoute {
                #Get("test/:id") { req in
                    let slug = req.parameters.get("slug")
                    let nested = wrap(req.parameters.get("nested"))
                    return slug ?? nested
                }
            }
            """
        } diagnostics: {
            """
            @Router
            struct MyRoute {
                #Get("test/:id") { req in
                    let slug = req.parameters.get("slug")
                               ┬─────────────────────────
                               ╰─ 🛑 Required path parameter is not declared in this route URL.
                    let nested = wrap(req.parameters.get("nested"))
                                      ┬───────────────────────────
                                      ╰─ 🛑 Required path parameter is not declared in this route URL.
                    return slug ?? nested
                }
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func ignoresBypassedParameterAccess() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router
            struct MyRoute {
                #Get("test/:id") { req in
                    let slug = #Bypass { try req.parameters.require("slug") }
                    return slug
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "test", ":id", use: __macro_local_12RouteHandlerfMu_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        let slug = try req.parameters.require("slug")
                        return slug
                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func warnsForDynamicPathParameterAccess() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router
            struct MyRoute {
                #Get("test/:id") { req in
                    let key = "id"
                    let id = req.parameters.get(key)
                    return id
                }
            }
            """
        } diagnostics: {
            """
            @Router
            struct MyRoute {
                #Get("test/:id") { req in
                    let key = "id"
                    let id = req.parameters.get(key)
                             ┬──────────────────────
                             ╰─ ⚠️ Getting a route parameter from a variable is unsafe for static checking. Use a string literal, or wrap the expression in #Bypass to silence this warning.
                    return id
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "test", ":id", use: __macro_local_12RouteHandlerfMu_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        let key = "id"
                        let id = req.parameters.get(key)
                        return id
                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func downgradesParameterErrorsAndSuppressesWarnings() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
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
            """
        } diagnostics: {
            """
            @DisableParameterCheck(as: .warning)
            @Router
            struct MyRoute {
                #Get("test/:id") { req in
                    let key = "slug"
                    let dynamic = req.parameters.get(key)
                    let slug = try req.parameters.require("slug")
                                   ┬─────────────────────────────
                                   ╰─ ⚠️ Required path parameter is not declared in this route URL.
                    return dynamic ?? slug
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "test", ":id", use: __macro_local_12RouteHandlerfMu_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        let key = "slug"
                        let dynamic = req.parameters.get(key)
                        let slug = try req.parameters.require("slug")
                        return dynamic ?? slug
                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func bypassWarningModeDowngradesOnlyWrappedErrors() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
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
            """
        } diagnostics: {
            """
            @Router
            struct MyRoute {
                #Get("test/:id") { req in
                    let key = "slug"
                    let slug = #Bypass(as: .warning) { try req.parameters.require("slug") }
                                                           ┬─────────────────────────────
                                                           ╰─ ⚠️ Required path parameter is not declared in this route URL.
                    let dynamic = #Bypass(as: .warning) { req.parameters.get(key) }
                    return dynamic ?? slug
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "test", ":id", use: __macro_local_12RouteHandlerfMu_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        let key = "slug"
                        let slug = try req.parameters.require("slug")
                        let dynamic = req.parameters.get(key)
                        return dynamic ?? slug
                }
            }

            extension MyRoute: Vapor.RouteCollection {
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func webSocketRequiresTrailingClosure() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router
            struct MyRoute {
                #WebSocket("chat", action: {})
            }
            """
        } diagnostics: {
            """
            @Router
            struct MyRoute {
                #WebSocket("chat", action: {})
                ┬─────────────────────────────
                ╰─ 🛑 #WebSocket only supports trailing closures.
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func webSocketRejectsNonEventStatements() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router
            struct MyRoute {
                #WebSocket("chat") {
                    let value = 1
                }
            }
            """
        } diagnostics: {
            """
            @Router
            struct MyRoute {
                #WebSocket("chat") {
                    let value = 1
                    ┬────────────
                    ╰─ 🛑 #WebSocket bodies may only contain websocket event macros.
                }
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func webSocketRejectsInvalidEventSignatures() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
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
            """
        } diagnostics: {
            """
            @Router
            struct MyRoute {
                #WebSocket("chat") {
                    #OnText { text in
                    ╰─ 🛑 #OnText and #OnBinary handlers must accept exactly two parameters.
                        print(text)
                    }
            
                    #OnClose { ws in
                    ╰─ 🛑 #OnClose handlers must not declare parameters.
                        print(ws)
                    }
                }
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func webSocketRejectsUnexpectedAdditionalTrailingClosureLabel() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
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
            """
        } diagnostics: {
            """
            @Router
            struct MyRoute {
                #WebSocket("chat") {
                    ["X-Test": "1"]
                    ┬──────────────
                    ╰─ 🛑 #WebSocket bodies may only contain websocket event macros.
                } upgraded: {
                  ╰─ 🛑 #WebSocket only supports an additional trailing closure labeled didUpgrade:.
                    #OnClose {
                        print("closed")
                    }
                }
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }
}
