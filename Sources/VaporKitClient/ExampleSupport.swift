import Vapor

struct AuthMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request)
    }
}

struct AuditMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        request.logger.info("audit middleware executed")
        return next.respond(to: request)
    }
}

struct RateLimitMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        next.respond(to: request)
    }
}

struct UserDTO: Content {
    let id: UUID
    let email: String
    let username: String
    let age: Int
    let website: String?
}
