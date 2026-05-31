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
}

struct EchoPayload: Content {
    var message: String
}
