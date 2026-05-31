import Testing
import VaporKit
import VaporTesting

@Suite struct ValidationIntegrationTests {
    @Test func validatableModelWorksWithVaporContentValidation() async throws {
        try await withApp { app in
            app.post("_test", "integration", "accounts") { req -> HTTPStatus in
                try CreateAccountRequest.validate(content: req)
                _ = try req.content.decode(CreateAccountRequest.self)
                return .created
            }

            try await app.testing().test(.POST, "/_test/integration/accounts") { request in
                try request.content.encode(
                    CreateAccountRequest(
                        username: "user123",
                        email: "user@example.com",
                        password: "password123"
                    )
                )
            } afterResponse: { response in
                #expect(response.status == .created)
            }

            try await app.testing().test(.POST, "/_test/integration/accounts") { request in
                try request.content.encode(
                    CreateAccountRequest(
                        username: "no",
                        email: "not-an-email",
                        password: "short"
                    )
                )
            } afterResponse: { response in
                #expect(response.status == .badRequest)
            }
        }
    }
}
