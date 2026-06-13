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

@Router("/_test/integration/api")
struct VaporKitIntegrationAPIRouter {
    #Get("hello") { _ in
        "hello"
    }

    #Post("echo") { req -> String in
        let payload = try req.content.decode(EchoPayload.self)
        return payload.message
    }

    #On("status", method: .PATCH) { _ -> HTTPStatus in
        .accepted
    }

    @Middleware(IntegrationHeaderMiddleware())
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

    @Get("typed/:id")
    func typed(_ req: Request, @Path id: String) async throws -> String {
        "typed:\(id):\(req.method.rawValue)"
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
}

struct EchoPayload: Content {
    var message: String
}

struct SearchQuery: Decodable {
    var term: String
    var limit: Int
}

struct UpdateUserBody: Content {
    var name: String
}
