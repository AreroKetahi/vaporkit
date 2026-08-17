import VaporKit

struct IntegrationHeaderMiddleware: Middleware {
    func respond(
        to request: Request,
        chainingTo next: any Responder
    ) -> EventLoopFuture<Response> {
        next.respond(to: request).map { response in
            response.headers.replaceOrAdd(name: "X-VaporKit-Middleware", value: "applied")
            return response
        }
    }
}

struct IntegrationAuthenticatedUser: Authenticatable {
    static let guest = IntegrationAuthenticatedUser(name: "guest")

    var name: String
}

struct IntegrationAuthMiddleware: AsyncMiddleware {
    func respond(
        to request: Request,
        chainingTo next: any AsyncResponder
    ) async throws -> Response {
        if let name = request.headers.first(name: "X-Integration-User") {
            request.auth.login(IntegrationAuthenticatedUser(name: name))
        }

        return try await next.respond(to: request)
    }
}

@Router("/_test/integration/api")
struct VaporKitIntegrationAPIRouter {
    @OpenAPIResponse(body: String.self)
    #Get("hello") { _ in
        "hello"
    }

    #Post("echo") { req -> String in
        let payload = try req.content.decode(EchoPayload.self)
        return payload.message
    }

    @OpenAPIIgnored
    #On("status", method: .PATCH) { _ -> HTTPStatus in
        .accepted
    }

    @Middleware(IntegrationHeaderMiddleware())
    @OpenAPIResponse(body: String.self)
    #Get("middleware") { _ in
        "middleware"
    }

    @RouteHandler("named", method: .GET)
    func named(req: Request) -> String {
        "named"
    }

    #Register(VaporKitIntegrationUsersRouter())
}

@Router("users")
struct VaporKitIntegrationUsersRouter {
    #ForwardParameters("tenantID")

    #Get(":id") { req -> String in
        let id = try req.parameters.require("id")
        return "user:\(id)"
    }

    @OpenAPI(operationID: "getIntegrationUser", summary: "Get integration user", tags: ["Users"])
    @OpenAPIResponse(.ok, body: String.self)
    @Get("typed/:id")
    func typed(_ req: Request, @Path id: String) async throws -> String {
        "typed:\(id):\(req.method.rawValue)"
    }

    @Get("router-path/label/\(key: "value")")
    func routerPathLabel(_ req: Request, @Path value: String) -> String {
        "label:\(value)"
    }

    @Get("router-path/decoded/\("id", decoding: UUID.self)")
    func routerPathDecoded(_ req: Request, @Path id: UUID) -> String {
        "decoded:\(id.uuidString)"
    }

    @Get("router-path/converted/\("page", converting: Int.self)")
    func routerPathConverted(_ req: Request, @Path page: Int) -> String {
        "converted:\(page)"
    }

    @Middleware(IntegrationAuthMiddleware())
    @Get("typed-auth")
    func typedAuth(
        _ req: Request,
        @Auth user: IntegrationAuthenticatedUser
    ) async throws -> String {
        "auth:\(user.name):\(req.method.rawValue)"
    }

    @Middleware(IntegrationAuthMiddleware())
    @Get("typed-auth/optional")
    func typedOptionalAuth(
        _ req: Request,
        @Auth user: IntegrationAuthenticatedUser?
    ) async throws -> String {
        "auth:\(user?.name ?? "guest"):\(req.method.rawValue)"
    }

    @Middleware(IntegrationAuthMiddleware())
    @Get("typed-auth/default")
    func typedDefaultAuth(
        _ req: Request,
        @Auth user: IntegrationAuthenticatedUser = .guest
    ) async throws -> String {
        "auth:\(user.name):\(req.method.rawValue)"
    }

    @Get("typed/:id/query")
    func typedQuery(
        _ req: Request,
        @Path id: String,
        @Query input: SearchQuery,
        @Query("filter.name") filterName: String,
        @Query("page/number") page: Int
    ) async throws -> String {
        "query:\(id):\(input.term):\(input.limit):\(filterName):\(page)"
    }

    @Post("typed/:id/content")
    func typedContent(
        _ req: Request,
        @Path id: String,
        @Query("audit.reason") reason: String,
        @ContentBody body: UpdateUserBody
    ) async throws -> String {
        "content:\(id):\(reason):\(body.name)"
    }

    @Post("typed/:id/defaults")
    func typedDefaults(
        _ req: Request,
        @Path id: String,
        @Query("name") name: String?,
        @Query("page") page: Int = 1,
        @Query("mode") mode: String? = "full",
        @ContentBody body: UpdateUserBody = UpdateUserBody(name: "fallback")
    ) async throws -> String {
        "defaults:\(id):\(name ?? "nil"):\(page):\(mode ?? "nil"):\(body.name)"
    }
}

struct EchoPayload: Content {
    var message: String
}

@OpenAPISchema
struct SearchQuery: Codable {
    var term: String
    var limit: Int
}

@OpenAPISchema
struct UpdateUserBody: Content {
    var name: String
}
