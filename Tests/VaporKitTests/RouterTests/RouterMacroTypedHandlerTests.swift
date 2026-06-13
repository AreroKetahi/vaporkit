import Testing
import MacroTesting
import VaporKitMacros

@Suite(.macros([
    "Router": RouterMacro.self,
    "RouteHandler": EmptyMacro.self,
    "Get": EmptyMacro.self,
    "On": EmptyMacro.self,
    "Middleware": EmptyMacro.self,
    "DisableParameterCheck": EmptyMacro.self,
]))
struct RouterMacroTypedHandlerTests {
    @Test
    func registersTypedHandlerFunctions() throws {
    #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                @Get("users/:id")
                func find(req: Request, @Path("id") id: UUID) async throws -> UserDTO {
                    try await loadUser(req: req, id: id)
                }
            
                @On("users/:id", method: .DELETE)
                func remove(_ req: Vapor.Request, @Path("id") id: String) -> Bool {
                    true
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {
                func find(req: Request, @Path("id") id: UUID) async throws -> UserDTO {
                    try await loadUser(req: req, id: id)
                }
                func remove(_ req: Vapor.Request, @Path("id") id: String) -> Bool {
                    true
                }
            
                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "api", "users", ":id", use: __macro_local_4findfMu_)
                    routes.on(.DELETE, "api", "users", ":id", use: __macro_local_6removefMu_)
                }
            
                func __macro_local_4findfMu_(req: Vapor.Request) async throws -> UserDTO {
                    let __macro_local_2idfMu_ = try req.parameters.require("id", as: UUID.self)
                    return try await find(req: req, id: __macro_local_2idfMu_)
                }
            
                func __macro_local_6removefMu_(_ req: Vapor.Request) async throws -> Bool {
                    let __macro_local_2idfMu0_ = try req.parameters.require("id", as: String.self)
                    return remove(req, id: __macro_local_2idfMu0_)
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

    @Test
    func registersTypedHandlerFunctionsWithImplicitPathNames() throws {
    #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                @Get("projects/:key")
                func show(req: Request, @Path of key: UUID) async throws -> ProjectDTO {
                    try await loadProject(key: key, on: req.db)
                }
            
                @Get("users/:name")
                func find(req: Request, @Path() name: String) -> String {
                    name
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {
                func show(req: Request, @Path of key: UUID) async throws -> ProjectDTO {
                    try await loadProject(key: key, on: req.db)
                }
                func find(req: Request, @Path() name: String) -> String {
                    name
                }
            
                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "api", "projects", ":key", use: __macro_local_4showfMu_)
                    routes.on(.GET, "api", "users", ":name", use: __macro_local_4findfMu_)
                }
            
                func __macro_local_4showfMu_(req: Vapor.Request) async throws -> ProjectDTO {
                    let __macro_local_3keyfMu_ = try req.parameters.require("key", as: UUID.self)
                    return try await show(req: req, of: __macro_local_3keyfMu_)
                }
            
                func __macro_local_4findfMu_(req: Vapor.Request) async throws -> String {
                    let __macro_local_4namefMu_ = try req.parameters.require("name", as: String.self)
                    return find(req: req, name: __macro_local_4namefMu_)
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
    
    @Test
    func rejectsMissingRequiredPathParameterInTypedHandler() throws {
    #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                @Get("users/:id")
                func find(req: Request, @Path("slug") slug: String) -> Bool {
                    true
                }
            }
            """
        } diagnostics: {
            """
            @Router("api")
            struct MyRoute {
                @Get("users/:id")
                func find(req: Request, @Path("slug") slug: String) -> Bool {
                                        ┬────────────
                                        ╰─ 🛑 Required path parameter is not declared in this route URL.
                    true
                }
            }
            """
        }
    #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
    #endif
    }
}
