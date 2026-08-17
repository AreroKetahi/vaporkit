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

            @available(*, deprecated, message: "This property is an implementation detail of VaporKit. Do not use it directly.")
            private nonisolated let __macro_local_24VaporKitOpenAPI_accessorfMu_: VaporKit._OpenAPIRegisterAccessor = { outValue, type, _, _ in
                guard unsafe type.load(as: Any.Type.self) == VaporKit._OpenAPIRouterDescriptor.self else {
                    return false
                }

                unsafe outValue.initializeMemory(
                    as: VaporKit._OpenAPIRouterDescriptor.self,
                    to: VaporKit._OpenAPIRouterDescriptor(
                        identifier: "MyRoute",
                        path: "api",
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.existed", method: "GET", path: "is-existed", parameters: [], responses: [VaporKit._OpenAPIResponseDescriptor(status: .ok, body: Bool.self)], operationID: nil, summary: nil, description: nil, tags: []),
                            VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.remove", method: "DELETE", path: "users/:id", parameters: [], responses: [VaporKit._OpenAPIResponseDescriptor(status: .ok, body: Bool.self)], operationID: nil, summary: nil, description: nil, tags: [])],
                        registeredRouters: []
                    )
                )
                return true
            }

            #if objectFormat(MachO)
            @section("__DATA_CONST,__swift5_vkoa")
            #elseif objectFormat(ELF)
            @section("swift5_vkoa")
            #elseif objectFormat(COFF)
            @section(".sw5vkoa")
            #endif
            @used
            @available(*, deprecated, message: "This property is an implementation detail of VaporKit. Do not use it directly.")
            private let __macro_local_22VaporKitOpenAPI_recordfMu_: VaporKit._OpenAPIRegisterRecord = (
                0x766B_6F61,
                1,
                {
                    unsafe __macro_local_24VaporKitOpenAPI_accessorfMu_($0, $1, $2, $3)
                },
                0,
                0
            )

            extension MyRoute: Vapor.RouteCollection {
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
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
        } expansion: {
            """
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

            @available(*, deprecated, message: "This property is an implementation detail of VaporKit. Do not use it directly.")
            private nonisolated let __macro_local_24VaporKitOpenAPI_accessorfMu_: VaporKit._OpenAPIRegisterAccessor = { outValue, type, _, _ in
                guard unsafe type.load(as: Any.Type.self) == VaporKit._OpenAPIRouterDescriptor.self else {
                    return false
                }

                unsafe outValue.initializeMemory(
                    as: VaporKit._OpenAPIRouterDescriptor.self,
                    to: VaporKit._OpenAPIRouterDescriptor(
                        identifier: "MyRoute",
                        path: "api",
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.index", method: "GET", path: "", parameters: [], responses: [VaporKit._OpenAPIResponseDescriptor(status: .ok, body: Bool.self)], operationID: nil, summary: nil, description: nil, tags: []),
                            VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.create", method: "POST", path: "", parameters: [], responses: [VaporKit._OpenAPIResponseDescriptor(status: .ok, body: Bool.self)], operationID: nil, summary: nil, description: nil, tags: [])],
                        registeredRouters: []
                    )
                )
                return true
            }

            #if objectFormat(MachO)
            @section("__DATA_CONST,__swift5_vkoa")
            #elseif objectFormat(ELF)
            @section("swift5_vkoa")
            #elseif objectFormat(COFF)
            @section(".sw5vkoa")
            #endif
            @used
            @available(*, deprecated, message: "This property is an implementation detail of VaporKit. Do not use it directly.")
            private let __macro_local_22VaporKitOpenAPI_recordfMu_: VaporKit._OpenAPIRegisterRecord = (
                0x766B_6F61,
                1,
                {
                    unsafe __macro_local_24VaporKitOpenAPI_accessorfMu_($0, $1, $2, $3)
                },
                0,
                0
            )

            extension MyRoute: Vapor.RouteCollection {
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
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
        throw Test.cancel("macros are only supported when running tests for the host platform")
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

            @available(*, deprecated, message: "This property is an implementation detail of VaporKit. Do not use it directly.")
            private nonisolated let __macro_local_24VaporKitOpenAPI_accessorfMu_: VaporKit._OpenAPIRegisterAccessor = { outValue, type, _, _ in
                guard unsafe type.load(as: Any.Type.self) == VaporKit._OpenAPIRouterDescriptor.self else {
                    return false
                }

                unsafe outValue.initializeMemory(
                    as: VaporKit._OpenAPIRouterDescriptor.self,
                    to: VaporKit._OpenAPIRouterDescriptor(
                        identifier: "MyRoute",
                        path: "api",
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.remove", method: "DELETE", path: "users/:id", parameters: [], responses: [VaporKit._OpenAPIResponseDescriptor(status: .ok, body: Bool.self)], operationID: nil, summary: nil, description: nil, tags: [])],
                        registeredRouters: []
                    )
                )
                return true
            }

            #if objectFormat(MachO)
            @section("__DATA_CONST,__swift5_vkoa")
            #elseif objectFormat(ELF)
            @section("swift5_vkoa")
            #elseif objectFormat(COFF)
            @section(".sw5vkoa")
            #endif
            @used
            @available(*, deprecated, message: "This property is an implementation detail of VaporKit. Do not use it directly.")
            private let __macro_local_22VaporKitOpenAPI_recordfMu_: VaporKit._OpenAPIRegisterRecord = (
                0x766B_6F61,
                1,
                {
                    unsafe __macro_local_24VaporKitOpenAPI_accessorfMu_($0, $1, $2, $3)
                },
                0,
                0
            )

            extension MyRoute: Vapor.RouteCollection {
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func rejectsMissingRequiredPathParameterInRouteHandler() throws {
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
            """
            @Router
            struct MyRoute {
                @RouteHandler("users/:id", method: .GET)
                func show(req: Request) throws -> String {
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

            @available(*, deprecated, message: "This property is an implementation detail of VaporKit. Do not use it directly.")
            private nonisolated let __macro_local_24VaporKitOpenAPI_accessorfMu_: VaporKit._OpenAPIRegisterAccessor = { outValue, type, _, _ in
                guard unsafe type.load(as: Any.Type.self) == VaporKit._OpenAPIRouterDescriptor.self else {
                    return false
                }

                unsafe outValue.initializeMemory(
                    as: VaporKit._OpenAPIRouterDescriptor.self,
                    to: VaporKit._OpenAPIRouterDescriptor(
                        identifier: "MyRoute",
                        path: "",
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.show", method: "GET", path: "users/:id", parameters: [], responses: [VaporKit._OpenAPIResponseDescriptor(status: .ok, body: String.self)], operationID: nil, summary: nil, description: nil, tags: [])],
                        registeredRouters: []
                    )
                )
                return true
            }

            #if objectFormat(MachO)
            @section("__DATA_CONST,__swift5_vkoa")
            #elseif objectFormat(ELF)
            @section("swift5_vkoa")
            #elseif objectFormat(COFF)
            @section(".sw5vkoa")
            #endif
            @used
            @available(*, deprecated, message: "This property is an implementation detail of VaporKit. Do not use it directly.")
            private let __macro_local_22VaporKitOpenAPI_recordfMu_: VaporKit._OpenAPIRegisterRecord = (
                0x766B_6F61,
                1,
                {
                    unsafe __macro_local_24VaporKitOpenAPI_accessorfMu_($0, $1, $2, $3)
                },
                0,
                0
            )

            extension MyRoute: Vapor.RouteCollection {
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }
}
