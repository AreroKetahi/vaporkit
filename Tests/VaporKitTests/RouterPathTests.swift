import Testing
import VaporKit

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
