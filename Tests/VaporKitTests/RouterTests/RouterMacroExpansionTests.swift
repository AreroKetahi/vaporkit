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

                nonisolated(nonsending) func boot(routes: any Vapor.RoutesBuilder) async throws {
                    routes.on(.get, "api", "test", use: __macro_local_12RouteHandlerfMu_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.ResponseEncodable {
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
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.get.test", method: "get", path: "test", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: [])],
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

                #On("something/:id", method: .patch) { r in
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

                #On("something/:id", method: .patch) { r in
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

                nonisolated(nonsending) func boot(routes: any Vapor.RoutesBuilder) async throws {
                    routes.on(.get, "api", "test", use: __macro_local_12RouteHandlerfMu_)
                    routes.on(.post, "api", "test", "upload", use: __macro_local_12RouteHandlerfMu0_)
                    routes.on(.patch, "api", "something", ":id", use: __macro_local_12RouteHandlerfMu1_)
                    routes.on(.delete, "api", "item", use: __macro_local_12RouteHandlerfMu2_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.ResponseEncodable {
                        print(req.url)
                        return "ok"
                }

                func __macro_local_12RouteHandlerfMu0_(request: Vapor.Request) async throws -> some Vapor.ResponseEncodable {
                        return "uploaded"
                }

                func __macro_local_12RouteHandlerfMu1_(r: Vapor.Request) async throws -> some Vapor.ResponseEncodable {
                        let id = try r.parameters.require("id", as: UUID.self)
                        return id
                }

                func __macro_local_12RouteHandlerfMu2_(__macro_local_7requestfMu2_: Vapor.Request) async throws -> some Vapor.ResponseEncodable {
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
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.get.test", method: "get", path: "test", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: []),
                            VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.post.test/upload", method: "post", path: "test/upload", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: []),
                            VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.patch.something/:id", method: "patch", path: "something/:id", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: []),
                            VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.delete.item", method: "delete", path: "item", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: [])],
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

                #On(method: .patch) { req in
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

                #On(method: .patch) { req in
                ╰─ ⚠️ Cannot infer this route's response schema. Add an explicit closure return type or @OpenAPIResponse.
                    return req.method.string
                }
            }
            """
        } expansion: {
            """
            struct MyRoute {

                nonisolated(nonsending) func boot(routes: any Vapor.RoutesBuilder) async throws {
                    routes.on(.get, "api", use: __macro_local_12RouteHandlerfMu_)
                    routes.on(.patch, "api", use: __macro_local_12RouteHandlerfMu0_)
                }

                func __macro_local_12RouteHandlerfMu_(__macro_local_7requestfMu_: Vapor.Request) async throws -> some Vapor.ResponseEncodable {
                        "index"
                }

                func __macro_local_12RouteHandlerfMu0_(req: Vapor.Request) async throws -> some Vapor.ResponseEncodable {
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
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.get.", method: "get", path: "", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: []),
                            VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.patch.", method: "patch", path: "", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: [])],
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

                nonisolated(nonsending) func boot(routes: any Vapor.RoutesBuilder) async throws {
                    routes.grouped(AuthMiddleware(), RateLimitMiddleware()).on(.get, "api", "profile", use: __macro_local_12RouteHandlerfMu_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.ResponseEncodable {
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
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.get.profile", method: "get", path: "profile", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: [])],
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

                nonisolated(nonsending) func boot(routes: any Vapor.RoutesBuilder) async throws {
                    routes.on(.get, "api", "health", use: __macro_local_12RouteHandlerfMu_)
                    routes.on(.post, "api", "users", use: __macro_local_12RouteHandlerfMu0_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> HTTPStatus {
                        return .ok
                }

                func __macro_local_12RouteHandlerfMu0_(req: Vapor.Request) async throws -> some Vapor.ResponseEncodable {
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
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.get.health", method: "get", path: "health", parameters: [], responses: [VaporKit._OpenAPIResponseDescriptor(status: .ok, body: HTTPStatus.self)], operationID: nil, summary: nil, description: nil, tags: []),
                            VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.post.users", method: "post", path: "users", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: [])],
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

                nonisolated(nonsending) func boot(routes: any Vapor.RoutesBuilder) async throws {
                    routes.on(.post, "api", "users", use: __macro_local_12RouteHandlerfMu_)
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
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.post.users", method: "post", path: "users", parameters: [], requestBody: VaporKit._OpenAPIRequestBodyDescriptor(body: CreateUser.self, contentType: "application/vnd.api+json", required: false), responses: [VaporKit._OpenAPIResponseDescriptor(status: .ok, body: UserDTO.self)], operationID: nil, summary: nil, description: nil, tags: [])],
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

                nonisolated(nonsending) func boot(routes: any Vapor.RoutesBuilder) async throws {
                    try await routes.grouped("api", ":tenantID").register(collection: UserRoutes())
                    try await routes.grouped("api", ":tenantID").register(collection: AdminRoutes())
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

                nonisolated(nonsending) func boot(routes: any Vapor.RoutesBuilder) async throws {
                    routes.on(.get, "users", ":id", "profile", use: __macro_local_12RouteHandlerfMu_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.ResponseEncodable {
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
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "MyRoute.get.profile", method: "get", path: "profile", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: [])],
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

                nonisolated(nonsending) func boot(routes: any Vapor.RoutesBuilder) async throws {
                    routes.on(.get, "api", "status", use: __macro_local_12RouteHandlerfMu_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.ResponseEncodable {
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
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "RouterDisabledRoute.get.status", method: "get", path: "status", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: [])],
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

                nonisolated(nonsending) func boot(routes: any Vapor.RoutesBuilder) async throws {
                    routes.on(.get, "api", "status", use: __macro_local_12RouteHandlerfMu_)
                }

                func __macro_local_12RouteHandlerfMu_(req: Vapor.Request) async throws -> some Vapor.ResponseEncodable {
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
                        handlers: [VaporKit._OpenAPIHandlerDescriptor(identifier: "RouteDisabledRoute.get.status", method: "get", path: "status", parameters: [], responses: [], operationID: nil, summary: nil, description: nil, tags: [])],
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

                nonisolated(nonsending) func boot(routes: any Vapor.RoutesBuilder) async throws {
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

                nonisolated(nonsending) func boot(routes: any Vapor.RoutesBuilder) async throws {
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

                nonisolated(nonsending) func boot(routes: any Vapor.RoutesBuilder) async throws {
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
