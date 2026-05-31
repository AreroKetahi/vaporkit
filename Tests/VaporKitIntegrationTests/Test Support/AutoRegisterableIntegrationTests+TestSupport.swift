import VaporKit

@AutoRegisterable
@Router("/_test/integration/auto")
struct VaporKitAutoRegisteredRouter {
    #Get("ping") { _ in
        "auto-ok"
    }
}
