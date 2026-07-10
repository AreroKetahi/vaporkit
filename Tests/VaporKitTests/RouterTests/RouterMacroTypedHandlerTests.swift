import Testing
import MacroTesting
import VaporKitMacros

@Suite(.macros([
    "Router": RouterMacro.self,
    "RouteHandler": EmptyMacro.self,
    "Get": EmptyMacro.self,
    "Post": EmptyMacro.self,
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
    func registersTypedHandlerFunctionsWithQueryParameters() throws {
    #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                @Get("projects/:id/search")
                func search(
                    req: Request,
                    @Path id: UUID,
                    @Query input: SearchQuery,
                    @Query("filter.name") name: String,
                    @Query("page/number") page: Int
                ) async throws -> [ProjectDTO] {
                    try await searchProjects(id: id, input: input, name: name, page: page, on: req.db)
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {
                func search(
                    req: Request,
                    @Path id: UUID,
                    @Query input: SearchQuery,
                    @Query("filter.name") name: String,
                    @Query("page/number") page: Int
                ) async throws -> [ProjectDTO] {
                    try await searchProjects(id: id, input: input, name: name, page: page, on: req.db)
                }
            
                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "api", "projects", ":id", "search", use: __macro_local_6searchfMu_)
                }
            
                func __macro_local_6searchfMu_(req: Vapor.Request) async throws -> [ProjectDTO] {
                    let __macro_local_2idfMu_ = try req.parameters.require("id", as: UUID.self)
                    let __macro_local_5inputfMu_ = try req.query.decode(SearchQuery.self)
                    let __macro_local_4namefMu_ = try req.query.get(String.self, at: "filter", "name")
                    let __macro_local_4pagefMu_ = try req.query.get(Int.self, at: "page", "number")
                    return try await search(req: req, id: __macro_local_2idfMu_, input: __macro_local_5inputfMu_, name: __macro_local_4namefMu_, page: __macro_local_4pagefMu_)
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
    func registersTypedHandlerFunctionsWithContentParameters() throws {
    #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                @Post("projects/:id")
                func update(
                    req: Request,
                    @Path id: UUID,
                    @Query("audit.reason") reason: String,
                    @ContentBody body: UpdateProjectBody
                ) async throws -> ProjectDTO {
                    try await updateProject(id: id, reason: reason, body: body, on: req.db)
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {
                func update(
                    req: Request,
                    @Path id: UUID,
                    @Query("audit.reason") reason: String,
                    @ContentBody body: UpdateProjectBody
                ) async throws -> ProjectDTO {
                    try await updateProject(id: id, reason: reason, body: body, on: req.db)
                }
            
                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.POST, "api", "projects", ":id", use: __macro_local_6updatefMu_)
                }
            
                func __macro_local_6updatefMu_(req: Vapor.Request) async throws -> ProjectDTO {
                    let __macro_local_2idfMu_ = try req.parameters.require("id", as: UUID.self)
                    let __macro_local_6reasonfMu_ = try req.query.get(String.self, at: "audit", "reason")
                    let __macro_local_4bodyfMu_ = try req.content.decode(UpdateProjectBody.self)
                    return try await update(req: req, id: __macro_local_2idfMu_, reason: __macro_local_6reasonfMu_, body: __macro_local_4bodyfMu_)
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
    func registersTypedHandlerFunctionsWithAuthParameters() throws {
    #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                @Get("profile")
                func profile(req: Request, @Auth user: User) async throws -> UserDTO {
                    try await loadProfile(for: user, on: req.db)
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {
                func profile(req: Request, @Auth user: User) async throws -> UserDTO {
                    try await loadProfile(for: user, on: req.db)
                }

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "api", "profile", use: __macro_local_7profilefMu_)
                }

                func __macro_local_7profilefMu_(req: Vapor.Request) async throws -> UserDTO {
                    let __macro_local_4userfMu_ = try req.auth.require(User.self)
                    return try await profile(req: req, user: __macro_local_4userfMu_)
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
    func registersTypedHandlerFunctionsWithOptionalAuthParameters() throws {
    #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                @Get("profile")
                func profile(req: Request, @Auth user: User?) -> String {
                    user?.name ?? "guest"
                }

                @Get("profile/default")
                func defaulted(req: Request, @Auth user: User = .guest) -> String {
                    user.name
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {
                func profile(req: Request, @Auth user: User?) -> String {
                    user?.name ?? "guest"
                }
                func defaulted(req: Request, @Auth user: User = .guest) -> String {
                    user.name
                }

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "api", "profile", use: __macro_local_7profilefMu_)
                    routes.on(.GET, "api", "profile", "default", use: __macro_local_9defaultedfMu_)
                }

                func __macro_local_7profilefMu_(req: Vapor.Request) async throws -> String {
                    let __macro_local_4userfMu_ = req.auth.get(User.self)
                    return profile(req: req, user: __macro_local_4userfMu_)
                }

                func __macro_local_9defaultedfMu_(req: Vapor.Request) async throws -> String {
                    let __macro_local_4userfMu0_ = req.auth.get(User.self)
                    return defaulted(req: req, user: __macro_local_4userfMu0_ ?? .guest)
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
    func registersTypedHandlerFunctionsWithAuthMixedWithOtherInjectedParameters() throws {
    #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                @Post("users/:id/profile")
                func updateProfile(
                    _ req: Request,
                    @Path id: UUID,
                    @Auth user: User?,
                    @Query("audit.reason") reason: String = "manual",
                    @ContentBody body: UpdateProfileBody
                ) async throws -> UserDTO {
                    try await update(id: id, user: user, reason: reason, body: body, on: req.db)
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {
                func updateProfile(
                    _ req: Request,
                    @Path id: UUID,
                    @Auth user: User?,
                    @Query("audit.reason") reason: String = "manual",
                    @ContentBody body: UpdateProfileBody
                ) async throws -> UserDTO {
                    try await update(id: id, user: user, reason: reason, body: body, on: req.db)
                }

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.POST, "api", "users", ":id", "profile", use: __macro_local_13updateProfilefMu_)
                }

                func __macro_local_13updateProfilefMu_(_ req: Vapor.Request) async throws -> UserDTO {
                    let __macro_local_2idfMu_ = try req.parameters.require("id", as: UUID.self)
                    let __macro_local_4userfMu_ = req.auth.get(User.self)
                    let __macro_local_6reasonfMu_ = try? req.query.get(String.self, at: "audit", "reason")
                    let __macro_local_4bodyfMu_ = try req.content.decode(UpdateProfileBody.self)
                    return try await updateProfile(req, id: __macro_local_2idfMu_, user: __macro_local_4userfMu_, reason: __macro_local_6reasonfMu_ ?? "manual", body: __macro_local_4bodyfMu_)
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
    func registersTypedHandlerFunctionsWithOptionalAndDefaultInjectedParameters() throws {
    #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                @Post("projects/:id/defaults")
                func update(
                    req: Request,
                    @Path id: UUID,
                    @Query("filter.name") name: String?,
                    @Query("page") page: Int = 1,
                    @Query("mode") mode: String? = "full",
                    @ContentBody body: UpdateProjectBody?,
                    @ContentBody fallback: UpdateProjectBody = .empty
                ) async throws -> ProjectDTO {
                    try await updateProject(id: id, name: name, page: page, mode: mode, body: body, fallback: fallback, on: req.db)
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {
                func update(
                    req: Request,
                    @Path id: UUID,
                    @Query("filter.name") name: String?,
                    @Query("page") page: Int = 1,
                    @Query("mode") mode: String? = "full",
                    @ContentBody body: UpdateProjectBody?,
                    @ContentBody fallback: UpdateProjectBody = .empty
                ) async throws -> ProjectDTO {
                    try await updateProject(id: id, name: name, page: page, mode: mode, body: body, fallback: fallback, on: req.db)
                }
            
                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.POST, "api", "projects", ":id", "defaults", use: __macro_local_6updatefMu_)
                }
            
                func __macro_local_6updatefMu_(req: Vapor.Request) async throws -> ProjectDTO {
                    let __macro_local_2idfMu_ = try req.parameters.require("id", as: UUID.self)
                    let __macro_local_4namefMu_ = try? req.query.get(String.self, at: "filter", "name")
                    let __macro_local_4pagefMu_ = try? req.query.get(Int.self, at: "page")
                    let __macro_local_4modefMu_ = try? req.query.get(String?.self, at: "mode")
                    let __macro_local_4bodyfMu_ = try? req.content.decode(UpdateProjectBody.self)
                    let __macro_local_8fallbackfMu_ = try? req.content.decode(UpdateProjectBody.self)
                    return try await update(req: req, id: __macro_local_2idfMu_, name: __macro_local_4namefMu_, page: __macro_local_4pagefMu_ ?? 1, mode: __macro_local_4modefMu_ ?? "full", body: __macro_local_4bodyfMu_, fallback: __macro_local_8fallbackfMu_ ?? .empty)
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

    @Test
    func rejectsDynamicQueryParameterKeyInTypedHandler() throws {
    #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                @Get("search")
                func search(req: Request, @Query(key) name: String) -> String {
                    name
                }
            }
            """
        } diagnostics: {
            """
            @Router("api")
            struct MyRoute {
                @Get("search")
                func search(req: Request, @Query(key) name: String) -> String {
                                          ┬──────────
                                          ╰─ 🛑 @Query requires a static string key.
                    name
                }
            }
            """
        }
    #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
    #endif
    }
}
