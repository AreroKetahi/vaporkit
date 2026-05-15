import Testing
import MacroTesting
import VaporKitMacros

@Suite(.macros([
    "Router": RouterMacro.self,
    "RouteHandler": EmptyMacro.self,
    "Middleware": EmptyMacro.self,
    "DisableParameterCheck": EmptyMacro.self,
]))
struct RouteHandlerMacroTests {
    @Test
    func registersAnnotatedHandlerFunctions() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                @RouteHandler("is-existed", method: .GET)
                func existed(req: Request) -> Bool {
                    true
                }
            
                @RouteHandler("users", ":id", method: .DELETE)
                func remove(req: Vapor.Request) -> Bool {
                    true
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {
                func existed(req: Request) -> Bool {
                    true
                }
                func remove(req: Vapor.Request) -> Bool {
                    true
                }
            
                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "api", "is-existed", use: existed)
                    routes.on(.DELETE, "api", "users", ":id", use: remove)
                }
            }
            
            extension MyRoute: Vapor.RouteCollection {
            }
            """
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test
    func registersAnnotatedHandlerFunctionsWithEmptyPath() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                @RouteHandler(method: .GET)
                func index(req: Request) -> Bool {
                    true
                }
            
                @RouteHandler(nil, method: .POST)
                func create(req: Vapor.Request) -> Bool {
                    true
                }
            }
            """
        } expansion: { """
            struct MyRoute {
                func index(req: Request) -> Bool {
                    true
                }
                func create(req: Vapor.Request) -> Bool {
                    true
                }
            
                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "api", use: index)
                    routes.on(.POST, "api", use: create)
                }
            }
            
            extension MyRoute: Vapor.RouteCollection {
            }
            """
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test
    func requiresSingleRequestParameter() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router
            struct MyRoute {
                @RouteHandler("bad", method: .GET)
                func invalid(id: String) -> Bool {
                    true
                }
            }
            """
        } diagnostics: {
            """
            @Router
            struct MyRoute {
                @RouteHandler("bad", method: .GET)
                ╰─ 🛑 @RouteHandler functions must accept exactly one parameter of type Request or Vapor.Request.
                func invalid(id: String) -> Bool {
                    true
                }
            }
            """
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test
    func registersAnnotatedHandlerFunctionsWithMiddleware() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                @Middleware(AuthMiddleware(), AuditMiddleware())
                @RouteHandler("users", ":id", method: .DELETE)
                func remove(req: Vapor.Request) -> Bool {
                    true
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {
                func remove(req: Vapor.Request) -> Bool {
                    true
                }
            
                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.grouped(AuthMiddleware(), AuditMiddleware()).on(.DELETE, "api", "users", ":id", use: remove)
                }
            }
            
            extension MyRoute: Vapor.RouteCollection {
            }
            """
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testRejectsMissingRequiredPathParameterInRouteHandler() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router
            struct MyRoute {
                @RouteHandler("users/:id", method: .GET)
                func show(req: Request) throws -> String {
                    let slug = try req.parameters.require("slug")
                    return slug
                }
            }
            """
        } diagnostics: {
            "Required path parameter is not declared in this route URL."
        } expansion: {
            """
            struct MyRoute {
                func show(req: Request) throws -> String {
                    let slug = try req.parameters.require("slug")
                    return slug
                }
            
                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "users", ":id", use: show)
                }
            }
            
            extension MyRoute: Vapor.RouteCollection {
            }
            """
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test
    func disablesParameterCheckForRouteHandler() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router
            struct MyRoute {
                @DisableParameterCheck
                @RouteHandler("users/:id", method: .GET)
                func show(req: Request) throws -> String {
                    let slug = try req.parameters.require("slug")
                    return slug
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {
                func show(req: Request) throws -> String {
                    let slug = try req.parameters.require("slug")
                    return slug
                }
            
                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "users", ":id", use: show)
                }
            }
            
            extension MyRoute: Vapor.RouteCollection {
            }
            """
        }
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
