# Testing a Vapor Application

Exercise generated routes with Swift Testing and VaporTesting.

## Overview

Add Vapor's `VaporTesting` product to your test target alongside VaporKit:

```swift
.testTarget(
    name: "AppTests",
    dependencies: [
        "App",
        .product(name: "VaporKit", package: "vaporkit"),
        .product(name: "VaporTesting", package: "vapor"),
    ]
)
```

The package must declare Vapor as a direct dependency to reference its product.
Use the same Vapor 5 version range as the application.

### Test a Route

`withApp` manages the test application's lifetime. Register routes before
entering `app.testing`, then send requests through the provided client:

```swift
import Testing
import Vapor
import VaporKit
import VaporTesting

@Router("health")
struct HealthRoutes {
    #Get { _ in "ok" }
}

@Suite
struct HealthTests {
    @Test
    func respondsToHealthCheck() async throws {
        try await withApp { app in
            try await app.register(collection: HealthRoutes())

            try await app.testing { client in
                let response = try await client.get("/health")
                #expect(response.status == .ok)
                try #expect(await response.body.requireString() == "ok")
            }
        }
    }
}
```

Vapor 5 responses have streaming bodies. Consume the body asynchronously rather
than using Vapor 4's `response.body.string`. Route registration, request body
decoding, and content validation are also asynchronous.

### Test Configuration and Lifecycle

Test your `VaporAppConfiguration` values directly with an application from
`withApp`. For lifecycle events, inject an actor that records callbacks into
your handlers. Vapor 5 no longer provides the Vapor 4 `StorageKey` and
`application.storage` APIs; a dedicated recorder gives the test explicit,
concurrency-safe ownership of its events.

The manifest configures stages in declaration order, then installs lifecycle
handlers. Boot callbacks run in declaration order and shutdown callbacks run
in reverse order. Command parsing tests alone do not verify startup behavior
or whether passthrough configuration changes the application's settings.

### Run on Linux

On macOS with Apple's `container` CLI installed:

```sh
CONTAINER_MEMORY=8G ./test-linux.sh --scratch-path .build-linux
```

Keep Linux build state in `.build-linux` instead of sharing macOS `.build`.
The script forwards additional arguments to `swift test`, so a focused run can
also include `--filter HealthTests`.

## See Also

- <doc:ApplicationEntryPoint>
- <doc:RunningAVaporApplication>
