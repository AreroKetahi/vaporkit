import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import MacroTesting
import Testing

@Suite(.macros(testMacros))
struct RouterMacroExpansionTests {
    @Test func autoRegisterableRouterEmitsRuntimeRecord() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @AutoRegisterable
            @Router("api")
            struct MyRoute {
                #Get("test") { req in
                    "ok"
                }
            }
            """
        } diagnostics: {
            """
            @AutoRegisterable
            @Router("api")
            struct MyRoute {
                #Get("test") { req in
                ╰─ ⚠️ Cannot infer this route's response schema. Add an explicit closure return type or @OpenAPIResponse.
                    "ok"
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "api", "test", use: __macro_local_12RouteHandlerfMu_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        "ok"
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
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.GET.test", method: "GET", path: "test", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: [])],
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

            @available(*, deprecated, message: "This property is an implementation detail of VaporKit. Do not use it directly.")
            private nonisolated let __macro_local_29VaporKitAutoRegister_accessorfMu_: VaporKit._RouteRegisterAccessor = { outValue, type, _, _ in
                guard unsafe type.load(as: Any.Type.self) == VaporKit._RouteDescriptor.self else {
                    return false
                }

                unsafe outValue.initializeMemory(
                    as: VaporKit._RouteDescriptor.self,
                    to: VaporKit._RouteDescriptor(
                        id: "MyRoute",
                        routerName: "MyRoute",
                        makeCollection: {
                            MyRoute()
                        }
                    )
                )

                return true
            }

            #if objectFormat(MachO)
            @section("__DATA_CONST,__swift5_vpkt")
            #elseif objectFormat(ELF)
            @section("swift5_vpkt")
            #elseif objectFormat(COFF)
            @section(".sw5vpkt")
            #endif
            @used
            @available(*, deprecated, message: "This property is an implementation detail of VaporKit. Do not use it directly.")
            private let __macro_local_27VaporKitAutoRegister_recordfMu_: VaporKit._RouteRegisterRecord = (
                0x766B_7274,
                1,
                {
                    unsafe __macro_local_29VaporKitAutoRegister_accessorfMu_($0, $1, $2, $3)
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

    @Test func registersFreestandingRoutes() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                #Get("test") { req in
                    print(req.url)
                    return "ok"
                }

                #Post("test/upload") { request in
                    return "uploaded"
                }

                #On("something/:id", method: .PATCH) { r in
                    let id = try r.parameters.require("id", as: UUID.self)
                    return id
                }

                #Delete("item") {
                    let result = try await $0.delete()
                    return result
                }
            }
            """
        } diagnostics: {
            """
            @Router("api")
            struct MyRoute {
                #Get("test") { req in
                ╰─ ⚠️ Cannot infer this route's response schema. Add an explicit closure return type or @OpenAPIResponse.
                    print(req.url)
                    return "ok"
                }

                #Post("test/upload") { request in
                ╰─ ⚠️ Cannot infer this route's response schema. Add an explicit closure return type or @OpenAPIResponse.
                    return "uploaded"
                }

                #On("something/:id", method: .PATCH) { r in
                ╰─ ⚠️ Cannot infer this route's response schema. Add an explicit closure return type or @OpenAPIResponse.
                    let id = try r.parameters.require("id", as: UUID.self)
                    return id
                }

                #Delete("item") {
                ╰─ ⚠️ Cannot infer this route's response schema. Add an explicit closure return type or @OpenAPIResponse.
                    let result = try await $0.delete()
                    return result
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "api", "test", use: __macro_local_12RouteHandlerfMu_)
                    routes.on(.POST, "api", "test", "upload", use: __macro_local_12RouteHandlerfMu0_)
                    routes.on(.PATCH, "api", "something", ":id", use: __macro_local_12RouteHandlerfMu1_)
                    routes.on(.DELETE, "api", "item", use: __macro_local_12RouteHandlerfMu2_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        print(req.url)
                        return "ok"
                }

                func __macro_local_12RouteHandlerfMu0_(request: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        return "uploaded"
                }

                func __macro_local_12RouteHandlerfMu1_(r: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        let id = try r.parameters.require("id", as: UUID.self)
                        return id
                }

                func __macro_local_12RouteHandlerfMu2_(__macro_local_7requestfMu2_: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        let result = try await __macro_local_7requestfMu2_.delete()
                        return result
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
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.GET.test", method: "GET", path: "test", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: []),
                            VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.POST.test/upload", method: "POST", path: "test/upload", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: []),
                            VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.PATCH.something/:id", method: "PATCH", path: "something/:id", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: []),
                            VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.DELETE.item", method: "DELETE", path: "item", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: [])],
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

    @Test func registersFreestandingRoutesWithEmptyPath() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                #Get {
                    "index"
                }

                #On(method: .PATCH) { req in
                    return req.method.string
                }
            }
            """
        } diagnostics: {
            """
            @Router("api")
            struct MyRoute {
                #Get {
                ╰─ ⚠️ Cannot infer this route's response schema. Add an explicit closure return type or @OpenAPIResponse.
                    "index"
                }

                #On(method: .PATCH) { req in
                ╰─ ⚠️ Cannot infer this route's response schema. Add an explicit closure return type or @OpenAPIResponse.
                    return req.method.string
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "api", use: __macro_local_12RouteHandlerfMu_)
                    routes.on(.PATCH, "api", use: __macro_local_12RouteHandlerfMu0_)
                }

                func __macro_local_12RouteHandlerfMu_(__macro_local_7requestfMu_: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        "index"
                }

                func __macro_local_12RouteHandlerfMu0_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        return req.method.string
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
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.GET.", method: "GET", path: "", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: []),
                            VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.PATCH.", method: "PATCH", path: "", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: [])],
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

    @Test func registersFreestandingRoutesWithMiddleware() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                @Middleware(AuthMiddleware(), RateLimitMiddleware())
                #Get("profile") { req in
                    req.url.path
                }
            }
            """
        } diagnostics: {
            """
            @Router("api")
            struct MyRoute {
                @Middleware(AuthMiddleware(), RateLimitMiddleware())
                ╰─ ⚠️ Cannot infer this route's response schema. Add an explicit closure return type or @OpenAPIResponse.
                #Get("profile") { req in
                    req.url.path
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.grouped(AuthMiddleware(), RateLimitMiddleware()).on(.GET, "api", "profile", use: __macro_local_12RouteHandlerfMu_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        req.url.path
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
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.GET.profile", method: "GET", path: "profile", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: [])],
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

    @Test func preservesExplicitFreestandingRouteReturnType() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                #Get("health") { req -> HTTPStatus in
                    return .ok
                }

                #Post("users") { req in
                    return "created"
                }
            }
            """
        } diagnostics: {
            """
            @Router("api")
            struct MyRoute {
                #Get("health") { req -> HTTPStatus in
                    return .ok
                }

                #Post("users") { req in
                ╰─ ⚠️ Cannot infer this route's response schema. Add an explicit closure return type or @OpenAPIResponse.
                    return "created"
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "api", "health", use: __macro_local_12RouteHandlerfMu_)
                    routes.on(.POST, "api", "users", use: __macro_local_12RouteHandlerfMu0_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> HTTPStatus {
                        return .ok
                }

                func __macro_local_12RouteHandlerfMu0_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        return "created"
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
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.GET.health", method: "GET", path: "health", parameters: [], responses: [VaporKit._OpenAPIResponseDescriptor(status: .ok, body: HTTPStatus.self)], operationID: nil, summary: nil, description: nil, tags: []),
                            VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.POST.users", method: "POST", path: "users", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: [])],
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

    @Test func explicitOpenAPIRequestDescribesFreestandingRouteBody() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                @OpenAPIRequest(
                    body: CreateUser.self,
                    contentType: "application/vnd.api+json",
                    required: false
                )
                #Post("users") { req -> UserDTO in
                    try await create(req.content.decode(CreateUser.self))
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.POST, "api", "users", use: __macro_local_12RouteHandlerfMu_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> UserDTO {
                        try await create(req.content.decode(CreateUser.self))
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
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.POST.users", method: "POST", path: "users", parameters: [], requestBody: VaporKit._OpenAPIRequestBodyDescriptor(body: CreateUser.self, contentType: "application/vnd.api+json", required: false), responses: [VaporKit._OpenAPIResponseDescriptor(status: .ok, body: UserDTO.self)], operationID: nil, summary: nil, description: nil, tags: [])],
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

    @Test func registersChildRouteCollectionsUnderRouterPrefix() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api/:tenantID")
            struct MyRoute {
                #Register(UserRoutes(), AdminRoutes())
            }
            """
        } expansion: {
            """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    try routes.grouped("api", ":tenantID").register(collection: UserRoutes())
                    try routes.grouped("api", ":tenantID").register(collection: AdminRoutes())
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
                        path: "api/:tenantID",
                        handlers: [],
                        registeredRouters: ["UserRoutes", "AdminRoutes"]
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

    @Test func forwardedParametersSatisfyRouteParameterValidation() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("users/:id")
            struct MyRoute {
                #ForwardParameters("tenantID")

                #Get("profile") { req in
                    let tenantID = try req.parameters.require("tenantID")
                    let id = try req.parameters.require("id")
                    return tenantID + ":" + id
                }
            }
            """
        } diagnostics: {
            """
            @Router("users/:id")
            struct MyRoute {
                #ForwardParameters("tenantID")

                #Get("profile") { req in
                ╰─ ⚠️ Cannot infer this route's response schema. Add an explicit closure return type or @OpenAPIResponse.
                    let tenantID = try req.parameters.require("tenantID")
                    let id = try req.parameters.require("id")
                    return tenantID + ":" + id
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "users", ":id", "profile", use: __macro_local_12RouteHandlerfMu_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        let tenantID = try req.parameters.require("tenantID")
                        let id = try req.parameters.require("id")
                        return tenantID + ":" + id
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
                        path: "users/:id",
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.GET.profile", method: "GET", path: "profile", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: [])],
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

    @Test func DisablesParameterCheckForRouterAndSingleRoute() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @DisableParameterCheck
            @Router("api")
            struct RouterDisabledRoute {
                #Get("status") { req in
                    try req.parameters.require("missing")
                }
            }
            """
        } diagnostics: {
            """
            @DisableParameterCheck
            @Router("api")
            struct RouterDisabledRoute {
                #Get("status") { req in
                ╰─ ⚠️ Cannot infer this route's response schema. Add an explicit closure return type or @OpenAPIResponse.
                    try req.parameters.require("missing")
                }
            }
            """
        } expansion: {
            """
            struct RouterDisabledRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "api", "status", use: __macro_local_12RouteHandlerfMu_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        try req.parameters.require("missing")
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
                        identifier: "RouterDisabledRoute",
                        path: "api",
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "RouterDisabledRoute.GET.status", method: "GET", path: "status", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: [])],
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

            extension RouterDisabledRoute: Vapor.RouteCollection {
            }
            """
        }

        assertMacro {
            """
            @Router("api")
            struct RouteDisabledRoute {
                @DisableParameterCheck
                #Get("status") { req in
                    try req.parameters.require("missing")
                }
            }
            """
        } diagnostics: {
            """
            @Router("api")
            struct RouteDisabledRoute {
                @DisableParameterCheck
                ╰─ ⚠️ Cannot infer this route's response schema. Add an explicit closure return type or @OpenAPIResponse.
                #Get("status") { req in
                    try req.parameters.require("missing")
                }
            }
            """
        } expansion: {
            """
            struct RouteDisabledRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.on(.GET, "api", "status", use: __macro_local_12RouteHandlerfMu_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.AsyncResponseEncodable {
                        try req.parameters.require("missing")
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
                        identifier: "RouteDisabledRoute",
                        path: "api",
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "RouteDisabledRoute.GET.status", method: "GET", path: "status", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: [])],
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

            extension RouteDisabledRoute: Vapor.RouteCollection {
            }
            """
        }
        #else
        throw Test.cancel("macros are only supported when running tests for the host platform")
        #endif
    }

    @Test func registersWebSocketRoutes() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                @Middleware(AuthMiddleware())
                #WebSocket("chat", maxFrameSize: 4096) { req in
                    ["X-Trace": req.id.uuidString]
                } didUpgrade: {
                    #OnText { ws, text in
                        await ws.send(text)
                    }

                    #OnBinary { ws, buffer in
                        await ws.send(buffer)
                    }

                    #OnClose {
                        print("closed")
                    }
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.grouped(AuthMiddleware()).webSocket("api", "chat", maxFrameSize: 4096, shouldUpgrade: __macro_local_22WebSocketShouldUpgradefMu_, onUpgrade: __macro_local_16WebSocketHandlerfMu_)
                }

                func __macro_local_22WebSocketShouldUpgradefMu_(req: Vapor.Request) async throws -> Vapor.HTTPHeaders? {
                        ["X-Trace": req.id.uuidString]
                }

                func __macro_local_16WebSocketHandlerfMu_(req: Vapor.Request, ws: Vapor.WebSocket) async {
                    let _ = req
                    ws.onText { ws, text in
                    await ws.send(text)
                    }
                    ws.onBinary { ws, buffer in
                        await ws.send(buffer)
                    }
                    ws.onClose.whenComplete { _ in
                        print("closed")
                    }
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
                        handlers: [],
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

    @Test func rewritesWebSocketEventShorthandArguments() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                #WebSocket("chat") { req in
                    nil
                } didUpgrade: {
                    #OnText {
                        await $0.send($1)
                    }

                    #OnBinary {
                        await $0.send($1)
                    }
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.webSocket("api", "chat", shouldUpgrade: __macro_local_22WebSocketShouldUpgradefMu_, onUpgrade: __macro_local_16WebSocketHandlerfMu_)
                }

                func __macro_local_22WebSocketShouldUpgradefMu_(req: Vapor.Request) async throws -> Vapor.HTTPHeaders? {
                        nil
                }

                func __macro_local_16WebSocketHandlerfMu_(req: Vapor.Request, ws: Vapor.WebSocket) async {
                    let _ = req
                    ws.onText { __macro_local_9webSocketfMu_, __macro_local_4textfMu_ in
                    await __macro_local_9webSocketfMu_.send(__macro_local_4textfMu_)
                    }
                    ws.onBinary { __macro_local_9webSocketfMu0_, __macro_local_6bufferfMu_ in
                        await __macro_local_9webSocketfMu0_.send(__macro_local_6bufferfMu_)
                    }
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
                        handlers: [],
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

    @Test func rewritesShorthandShouldUpgradeRequestToUniqueName() throws {
        #if canImport(VaporKitMacros)
        assertMacro {
            """
            @Router("api")
            struct MyRoute {
                #WebSocket("chat") {
                    ["X-Trace": $0.id.uuidString]
                } didUpgrade: {
                    #OnClose {
                        print("closed")
                    }
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {

                func boot(routes: any Vapor.RoutesBuilder) throws {
                    routes.webSocket("api", "chat", shouldUpgrade: __macro_local_22WebSocketShouldUpgradefMu_, onUpgrade: __macro_local_16WebSocketHandlerfMu_)
                }

                func __macro_local_22WebSocketShouldUpgradefMu_(__macro_local_7requestfMu_: Vapor.Request) async throws -> Vapor.HTTPHeaders? {
                        ["X-Trace": __macro_local_7requestfMu_.id.uuidString]
                }

                func __macro_local_16WebSocketHandlerfMu_(req: Vapor.Request, ws: Vapor.WebSocket) async {
                    let _ = req
                    ws.onClose.whenComplete { _ in
                    print("closed")
                    }
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
                        handlers: [],
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
