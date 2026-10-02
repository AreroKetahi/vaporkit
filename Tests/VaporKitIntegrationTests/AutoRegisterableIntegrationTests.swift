import Testing
import VaporKit
import VaporTesting

@Suite struct AutoRegisterableIntegrationTests {
    @Test func autoRegisterableRoutersAreDiscoveredAndRegistered() async throws {
        try await withApp { app in
            try await app.autoRegisterRouters()

            try await app.testing { client in
                let response = try await client.get("/_test/integration/auto/ping")
                #expect(response.status == .ok)
                try #expect(await response.body.requireString() == "auto-ok")
            }
        }
    }
}
