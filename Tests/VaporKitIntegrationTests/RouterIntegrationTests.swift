import Testing
import Foundation
import HTTPTypes
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
            try await app.register(collection: VaporKitIntegrationAPIRouter())
            
            try await app.testing { client in
                var response = try await client.get("/_test/integration/api/hello")
                #expect(response.status == .ok)
                try #expect(await response.body.requireString() == "hello")

                response = try await client.post("/_test/integration/api/echo", content: EchoPayload(message: "echoed"))
                #expect(response.status == .ok)
                try #expect(await response.body.requireString() == "echoed")

                response = try await client.patch("/_test/integration/api/status")
                #expect(response.status == .accepted)
            }
        }
    }

    @Test func middlewareRouteHandlerAndChildRoutersBehaveLikeNativeVaporRoutes() async throws {
        try await withApp { app in
            try await app.register(collection: VaporKitIntegrationAPIRouter())

            try await app.testing { client in
                var response = try await client.get("/_test/integration/api/middleware")
                #expect(response.status == .ok)
                #expect(response.headers[HTTPField.Name("X-VaporKit-Middleware")!] == "applied")
                try #expect(await response.body.requireString() == "middleware")

                response = try await client.get("/_test/integration/api/named")
                #expect(response.status == .ok)
                try #expect(await response.body.requireString() == "named")

                response = try await client.get("/_test/integration/api/users/42")
                #expect(response.status == .ok)
                try #expect(await response.body.requireString() == "user:42")

                response = try await client.get("/_test/integration/api/users/typed/42")
                #expect(response.status == .ok)
                try #expect(await response.body.requireString() == "typed:42:GET")

                response = try await client.get(
                "/_test/integration/api/users/router-path/label/vapor"
                )
                #expect(response.status == .ok)
                try #expect(await response.body.requireString() == "label:vapor")

                let id = UUID()
                response = try await client.get(
                    "/_test/integration/api/users/router-path/decoded/\(id.uuidString)"
                )
                #expect(response.status == .ok)
                try #expect(await response.body.requireString() == "decoded:\(id.uuidString)")

                response = try await client.get(
                "/_test/integration/api/users/router-path/decoded/not-a-uuid"
                )
                #expect(response.status == .unprocessableContent)

                response = try await client.get(
                "/_test/integration/api/users/router-path/converted/42"
                )
                #expect(response.status == .ok)
                try #expect(await response.body.requireString() == "converted:42")

                response = try await client.get(
                "/_test/integration/api/users/router-path/converted/not-an-int"
                )
                #expect(response.status == .unprocessableContent)

                let userHeader = HTTPField.Name("X-Integration-User")!
                response = try await client.get("/_test/integration/api/users/typed-auth") {
                    $0.headers[userHeader] = "vapor"
                }
                #expect(response.status == .ok)
                try #expect(await response.body.requireString() == "auth:vapor:GET")

                response = try await client.get("/_test/integration/api/users/typed-auth")
                #expect(response.status == .unauthorized)

                response = try await client.get("/_test/integration/api/users/typed-auth/optional")
                #expect(response.status == .ok)
                try #expect(await response.body.requireString() == "auth:guest:GET")

                response = try await client.get("/_test/integration/api/users/typed-auth/optional") {
                    $0.headers[userHeader] = "vapor"
                }
                #expect(response.status == .ok)
                try #expect(await response.body.requireString() == "auth:vapor:GET")

                response = try await client.get("/_test/integration/api/users/typed-auth/default")
                #expect(response.status == .ok)
                try #expect(await response.body.requireString() == "auth:guest:GET")

                response = try await client.get("/_test/integration/api/users/typed-auth/default") {
                    $0.headers[userHeader] = "vapor"
                }
                #expect(response.status == .ok)
                try #expect(await response.body.requireString() == "auth:vapor:GET")

                response = try await client.get(
                    "/_test/integration/api/users/typed/42/query?term=vapor&limit=2&filter[name]=owner&page[number]=3"
                )
                #expect(response.status == .ok)
                try #expect(await response.body.requireString() == "query:42:vapor:2:owner:3")

                response = try await client.post(
                    "/_test/integration/api/users/typed/42/content?audit[reason]=rename",
                    content: UpdateUserBody(name: "updated")
                )
                #expect(response.status == .ok)
                try #expect(await response.body.requireString() == "content:42:rename:updated")

                response = try await client.post(
                    "/_test/integration/api/users/typed/42/defaults?name=neo",
                    headers: [:]
                )
                #expect(response.status == .ok)
                try #expect(await response.body.requireString() == "defaults:42:neo:1:full:fallback")
            }
        }
    }
}
