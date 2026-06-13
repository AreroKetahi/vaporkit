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

// MARK: - Static Parameter Check Scope Preview

#if PreviewDiagnose

@Router("api/static-check/default")
struct DefaultStaticCheckRoutes {
    // Warning: dynamic parameter names are allowed, but cannot be proven by syntax-only checks.
    #Get(":id/dynamic") { req in
        let key = "id"
        return req.parameters.get(key) ?? "missing"
    }

    // No diagnostic: literal access matches the route path.
    #Get(":id/literal") { req in
        try req.parameters.require("id")
    }
}

@DisableParameterCheck(as: .warning)
@Router("api/static-check/router-warning")
struct RouterWarningStaticCheckRoutes {
    // Warning: this would normally be an error, but router-level warning mode downgrades it.
    #Get(":id/missing-literal") { req in
        try req.parameters.require("slug")
    }

    // No diagnostic: router-level warning mode suppresses lower-severity dynamic-name warnings.
    #Get(":id/dynamic") { req in
        let key = "id"
        return req.parameters.get(key) ?? "missing"
    }
}

@Router("api/static-check/route-scope")
struct RouteScopedStaticCheckRoutes {
    // Warning: only this route downgrades the missing literal parameter.
    @DisableParameterCheck(as: .warning)
    #Get(":id/route-warning") { req in
        try req.parameters.require("slug")
    }

    // No diagnostic: this route fully disables static parameter checks.
    @DisableParameterCheck
    #Get(":id/route-disabled") { req in
        try req.parameters.require("slug")
    }
}

@Router("api/static-check/bypass")
struct BypassStaticCheckRoutes {
    // Warning: only the wrapped expression is downgraded.
    #Get(":id/local-warning") { req in
        try #Bypass(as: .warning) {
            req.parameters.require("slug")
        }
    }

    // No diagnostic: the dynamic key warning is locally silenced.
    #Get(":id/local-disabled") { req in
        let key = "slug"
        return #Bypass {
            req.parameters.get(key)
        } ?? "missing"
    }
}

#endif

@Router
struct TypedParameterController {
    @Get(":id")
    func find(
        req: Request,
        @Path id: String,
        @Query("name") name: String,
        @ContentBody body: MyBody? = MyBody(key: "some", value: "any")
    ) -> some AsyncResponseEncodable {
        "\(id)-\(name)"
    }
    
    struct MyBody: Content {
        var key: String
        var value: String
    }
}
