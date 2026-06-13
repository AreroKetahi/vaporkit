import Testing
import VaporKit
import VaporTesting

@Suite struct RouterIntegrationTests {
    @Test func routerMacrosRegisterWorkingVaporRoutes() async throws {
        try await withApp { app in
            try app.register(collection: VaporKitIntegrationAPIRouter())

            try await app.testing().test(.GET, "/_test/integration/api/hello") { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "hello")
            }

            try await app.testing().test(.POST, "/_test/integration/api/echo") { request in
                try request.content.encode(EchoPayload(message: "echoed"))
            } afterResponse: { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "echoed")
            }

            try await app.testing().test(.PATCH, "/_test/integration/api/status") { response in
                #expect(response.status == .accepted)
            }
        }
    }

    @Test func middlewareRouteHandlerAndChildRoutersBehaveLikeNativeVaporRoutes() async throws {
        try await withApp { app in
            try app.register(collection: VaporKitIntegrationAPIRouter())

            try await app.testing().test(.GET, "/_test/integration/api/middleware") { response in
                #expect(response.status == .ok)
                #expect(response.headers.first(name: "X-VaporKit-Middleware") == "applied")
                #expect(response.body.string == "middleware")
            }

            try await app.testing().test(.GET, "/_test/integration/api/named") { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "named")
            }

            try await app.testing().test(.GET, "/_test/integration/api/users/42") { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "user:42")
            }

            try await app.testing().test(.GET, "/_test/integration/api/users/typed/42") { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "typed:42:GET")
            }

            try await app.testing().test(.GET, "/_test/integration/api/users/typed/42/query?term=vapor&limit=2&filter[name]=owner&page[number]=3") { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "query:42:vapor:2:owner:3")
            }
        }
    }
}
