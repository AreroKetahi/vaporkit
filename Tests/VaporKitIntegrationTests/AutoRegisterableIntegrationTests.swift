import Testing
import VaporKit
import VaporTesting

@Suite struct AutoRegisterableIntegrationTests {
    @Test func autoRegisterableRoutersAreDiscoveredAndRegistered() async throws {
        try await withApp { app in
            try app.autoRegisterRouters()

            try await app.testing().test(.GET, "/_test/integration/auto/ping") { response in
                #expect(response.status == .ok)
                #expect(response.body.string == "auto-ok")
            }
        }
    }
}
