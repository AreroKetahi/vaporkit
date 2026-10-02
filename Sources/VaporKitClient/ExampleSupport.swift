import Vapor
import VaporKit
import Foundation
import Logging

struct AuthMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: any Responder) async throws -> Response {
        try await next.respond(to: request)
    }
}

struct AuditMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: any Responder) async throws -> Response {
        Logger.current.info("audit middleware executed")
        return try await next.respond(to: request)
    }
}

struct RateLimitMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: any Responder) async throws -> Response {
        try await next.respond(to: request)
    }
}

@OpenAPISchema
struct UserDTO: Content {
    let id: UUID
    let email: String
    let username: String
    let age: Int
    let website: String?
}
