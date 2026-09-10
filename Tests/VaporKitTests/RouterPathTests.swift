import Testing
import VaporKit

struct RequestMetadata: Decodable {}

@Router("/router-path")
struct RouterPathInterpolationFixture {
    @Get("/decoded/\("id", decoding: UUID.self)")
    func decoded(req: Request, @Path("id") id: UUID) -> String {
        id.uuidString
    }

    @Get("/converted/\("page", converting: Int.self)")
    func converted(req: Request, @Path("page") page: Int) -> String {
        String(page)
    }

    @Get("/labeled/\(key: "slug")")
    func labeled(req: Request, @Path("slug") slug: String) -> String {
        slug
    }

    @RouteHandler("/raw/\(key: "value")", method: .GET)
    func raw(req: Request) throws -> String {
        try req.parameters.require("value")
    }

    @Get("/injected")
    func injected(
        req: Request,
        @Cookie cookies: [String: String],
        @Cookie(decoding: "profile") profile: RequestMetadata?,
        @Cookie(converting: "page") page: Int?,
        @Header headers: HTTPHeaders,
        @Header(key: "X-Value") values: [String],
        @Header(decoding: "X-Metadata") metadata: [RequestMetadata?],
        @Header(converting: "X-Number") numbers: [Int?]
    ) -> String {
        "\(cookies.count + headers.count + values.count + metadata.count + numbers.count + (profile == nil ? 0 : 1) + (page ?? 0))"
    }
}

@Suite
struct RouterPathTests {
    @Test func acceptsOnlyParameterInterpolations() {
        let _: RouterPath = "/users/\(key: "slug")"
        let _: RouterPath = "/users/\("id", decoding: UUID.self)"
        let _: RouterPath = "/pages/\("page", converting: Int.self)"
    }

    @Test func decodesCapturedPathParameters() throws {
        let expected = UUID()
        var parameters = Parameters()
        parameters.set("id", to: expected.uuidString)

        let decoded = try parameters.decode("id", as: UUID.self)
        #expect(decoded == expected)
    }
}
