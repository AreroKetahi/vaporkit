import VaporKit

@AutoRegisterable
@Router("/_test/integration/auto")
struct VaporKitAutoRegisteredRouter {
    @OpenAPIResponse(body: String.self)
    #Get("ping") { _ in
        "auto-ok"
    }
}
