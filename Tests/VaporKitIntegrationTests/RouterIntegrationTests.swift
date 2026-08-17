import Testing
import VaporKit
import VaporTesting

@Suite struct RouterIntegrationTests {
    @Test func openAPIRouterMetadataIsDiscoveredFromItsOwnSection() throws {
        let descriptors = _OpenAPIDiscovery.discover()
        let api = try #require(
            descriptors.first { $0.identifier == "VaporKitIntegrationAPIRouter" }
        )
        #expect(api.path == "/_test/integration/api")
        #expect(api.registeredRouters == ["VaporKitIntegrationUsersRouter"])

        let users = try #require(
            descriptors.first { $0.identifier == "VaporKitIntegrationUsersRouter" }
        )
        let typed = try #require(
            users.handlers.first { $0.identifier == "VaporKitIntegrationUsersRouter.typed" }
        )
        #expect(typed.path == "typed/:id")
        #expect(typed.operationID == "getIntegrationUser")
        #expect(typed.responses.first?.status == 200)

        let document = try OpenAPIDocumentBuilder().build(
            title: "Integration",
            version: "1",
            descriptors: [api, users]
        )
        #expect(document.paths["/_test/integration/api/users/typed/{id}"]?["get"] != nil)
        #expect(
            document.paths["/_test/integration/api/users/router-path/decoded/{id}"]?["get"]
            != nil
        )
    }

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

            try await app.testing().test(
                .GET,
                "/_test/integration/api/users/router-path/label/vapor"
            ) { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "label:vapor")
            }

            let id = UUID()
            try await app.testing().test(
                .GET,
                "/_test/integration/api/users/router-path/decoded/\(id.uuidString)"
            ) { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "decoded:\(id.uuidString)")
            }

            try await app.testing().test(
                .GET,
                "/_test/integration/api/users/router-path/decoded/not-a-uuid"
            ) { response in
                #expect(response.status == .unprocessableEntity)
            }

            try await app.testing().test(
                .GET,
                "/_test/integration/api/users/router-path/converted/42"
            ) { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "converted:42")
            }

            try await app.testing().test(
                .GET,
                "/_test/integration/api/users/router-path/converted/not-an-int"
            ) { response in
                #expect(response.status == .unprocessableEntity)
            }

            try await app.testing().test(.GET, "/_test/integration/api/users/typed-auth") { request in
                request.headers.replaceOrAdd(name: "X-Integration-User", value: "vapor")
            } afterResponse: { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "auth:vapor:GET")
            }

            try await app.testing().test(.GET, "/_test/integration/api/users/typed-auth") { response in
                #expect(response.status == .unauthorized)
            }

            try await app.testing().test(.GET, "/_test/integration/api/users/typed-auth/optional") { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "auth:guest:GET")
            }

            try await app.testing().test(.GET, "/_test/integration/api/users/typed-auth/optional") { request in
                request.headers.replaceOrAdd(name: "X-Integration-User", value: "vapor")
            } afterResponse: { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "auth:vapor:GET")
            }

            try await app.testing().test(.GET, "/_test/integration/api/users/typed-auth/default") { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "auth:guest:GET")
            }

            try await app.testing().test(.GET, "/_test/integration/api/users/typed-auth/default") { request in
                request.headers.replaceOrAdd(name: "X-Integration-User", value: "vapor")
            } afterResponse: { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "auth:vapor:GET")
            }

            try await app.testing().test(.GET, "/_test/integration/api/users/typed/42/query?term=vapor&limit=2&filter[name]=owner&page[number]=3") { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "query:42:vapor:2:owner:3")
            }

            try await app.testing().test(.POST, "/_test/integration/api/users/typed/42/content?audit[reason]=rename") { request in
                try request.content.encode(UpdateUserBody(name: "updated"))
            } afterResponse: { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "content:42:rename:updated")
            }

            try await app.testing().test(.POST, "/_test/integration/api/users/typed/42/defaults?name=neo") { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "defaults:42:neo:1:full:fallback")
            }
        }
    }
}
