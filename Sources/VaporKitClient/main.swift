import Vapor
import VaporKit

@ValidatableModel
struct CreateUserBody: Content {
    @Constraint(.email)
    var email: String

    @Constraint(
        .count(3...) && .ascii,
        message: "Username must be at least 3 ASCII characters"
    )
    var username: String

    @Constraint(.range(18...))
    var age: Int

    @Constraint(.count(...160), message: nil)
    var bio: String?

    @Constraint(.url, required: false)
    var website: String?
}

@ValidatableModel
struct UpdateUserBody: Content {
    @Constraint(.count(3...) && .ascii, required: false)
    var username: String?

    @Constraint(.range(18...))
    var age: Int?

    @Constraint(.url, required: false)
    var website: String?
}

@ValidatableModel
struct CreateAdminBody: Content {
    @Constraint(
        .count(8...),
        message: "Password must contain at least 8 characters"
    )
    var password: String

    @Constraint(.in("owner", "maintainer", "auditor"))
    var role: String

    @Constraint(
        validating: String.self,
        message: "Slug must not be empty",
        with: { value in
            !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    )
    var slug: String
}

@Router("api/users")
struct UserRoutes {
    @Middleware(AuthMiddleware())
    #Get(":id") { req in
        let id = try req.parameters.require("id", as: UUID.self)

        return UserDTO(
            id: id,
            email: "demo@example.com",
            username: "vapor_user",
            age: 24,
            website: "https://example.com"
        )
    }

    #Post("") { req in
        try CreateUserBody.validate(content: req)
        let body = try req.content.decode(CreateUserBody.self)

        return UserDTO(
            id: UUID(),
            email: body.email,
            username: body.username,
            age: body.age,
            website: body.website
        )
    }

    #Put(":id") { req in
        let id = try req.parameters.require("id", as: UUID.self)
        try UpdateUserBody.validate(content: req)
        let body = try req.content.decode(UpdateUserBody.self)

        return [
            "id": id.uuidString,
            "username": body.username ?? "unchanged",
            "website": body.website ?? "unchanged",
        ]
    }

    @Middleware(AuthMiddleware(), AuditMiddleware())
    @RouteHandler("exists", method: .GET)
    func exists(req: Request) -> Bool {
        let username: String? = req.query["username"]
        return username != nil
    }
}

@Router("api/admins")
struct AdminRoutes {
    #Post("") { req in
        try CreateAdminBody.validate(content: req)
        let body = try req.content.decode(CreateAdminBody.self)

        return [
            "role": body.role,
            "slug": body.slug,
        ]
    }

    #On(":id/reset-password", method: .PATCH) { req in
        let id = try req.parameters.require("id")
        return "password reset requested for \(id)"
    }
}

// MARK: - IDE Expansion Preview

@Router("/api/preview")
struct PreviewRoutes {
    @Middleware(AuthMiddleware(), RateLimitMiddleware())
    #Get("users/:id/profile") {
        let id = try $0.parameters.require("id")
        return "profile-\(id)"
    }

    #Delete("users/:id/sessions/:sessionID") { req in
        let userID = try req.parameters.require("id")
        let sessionID = try req.parameters.require("sessionID", as: UUID.self)
        return "\(userID)-\(sessionID.uuidString)"
    }

    @RouteHandler("health", method: .GET)
    func health(req: Vapor.Request) -> Bool {
        true
    }

    // `#Bypass` is the explicit escape hatch for syntax-only path parameter validation.
    #Get("unsafe/:id") { request in
        let slug = try #Bypass { request.parameters.require("slug") }
        return slug
    }

    #WebSocket("rooms", ":id", maxFrameSize: 4096) { req in
        ["X-Room": (try? req.parameters.require("id")) ?? "unknown"]
    } didUpgrade: {
        #OnText { ws, text in
            ws.send("echo: \(text)")
        }

        #OnBinary { ws, buffer in
            ws.send(buffer)
        }

        #OnClose {
            print("socket closed")
        }
    }
}
