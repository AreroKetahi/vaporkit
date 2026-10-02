# Application Entry Point

Control when a Vapor application starts and which commands can run independently.

## Overview

Adopt ``VaporApplication`` on your `@main` type to define startup through a
``VaporAppManifest``. VaporKit selects the command before it constructs the
Vapor application, allowing utility commands to run without executing unrelated
server setup.

This runtime capability is optional. Applications that don't need command-level
startup control can continue to use Vapor's standard entry point.

```swift
@main
struct MyServer: VaporApplication {
    static let manifest = VaporAppManifest(
        configurations: [AppSetup()],
        lifecycleHandlers: [ServerLifecycle()]
    )
}
```

### Configuring the Application

Add ``VaporAppConfiguration`` values to the manifest in the order they should
configure the application. VaporKit runs all configuration stages before boot.

```swift
struct AppSetup: VaporAppConfiguration {
    func configure(_ application: Application) async throws {
        application.middleware.use(FileMiddleware(
            publicDirectory: application.directory.publicDirectory
        ))
        try await application.autoRegisterRouters()
    }
}
```

### Observing the Lifecycle

Add Vapor `LifecycleHandler` values for boot and shutdown work. Boot
callbacks run in declaration order; shutdown callbacks run in reverse order.

```swift
struct ServerLifecycle: LifecycleHandler {
    func didBoot(_ application: Application) async throws {
        Logger.current.info("Server started")
    }

    func shutdown(_ application: Application) async {
        Logger.current.info("Server stopped")
    }
}
```

### Adding Commands

Expose additional ArgumentParser commands through
``VaporApplication/subcommands``. These commands remain independent from the
default Vapor server command.

```swift
struct Diagnose: AsyncParsableCommand {
    func run() async throws {
        print("Deployment is reachable")
    }
}

@main
struct MyServer: VaporApplication {
    static let manifest = VaporAppManifest()
    static let subcommands: [any ParsableCommand.Type] = [Diagnose.self]
}
```

### Configuring Server Creation

The manifest also owns `serverConfiguration`, `serviceConfiguration`, and
``VaporAppManifest/configReaderManifest``. These values are used to create the
Vapor application before configuration stages run. Configuration stages then
register routes, middleware, and other application behavior.

Use ``VaporConfigReaderManifest`` to choose configuration providers:

```swift
import Configuration
import Vapor
import VaporKit

static let manifest = VaporAppManifest(
    configurations: [AppSetup()],
    configReader: VaporConfigReaderManifest(
        providers: [EnvironmentVariablesProvider()]
    ),
    serverConfiguration: ServerConfiguration(),
    serviceConfiguration: Application.ServiceConfiguration()
)
```

The initializer label is `configReader`; the stored property is
`configReaderManifest`. The default manifest uses environment variables.
During startup, VaporKit prepends a command-line provider containing the
passthrough arguments. Providers are queried in order, so command-line values
override the manifest's providers. The resulting reader is shared by logging,
environment detection, and the application.

The `accessReporter` property is currently stored in the configuration manifest
but is not forwarded by the default server command.

See <doc:RunningAVaporApplication> for command-line examples and
<doc:TestingAVaporApplication> for testing routes without starting a server.

## Topics

### Defining the Entry Point

- ``VaporApplication``
- ``VaporApplication/manifest``
- ``VaporApplication/subcommands``
- ``VaporApplication/commandName``
- ``VaporApplication/abstract``
- ``VaporApplication/discussion``
- ``VaporApplication/version``
- ``VaporAppManifest``
- ``VaporConfigReaderManifest``

### Startup and Lifecycle

- ``VaporAppConfiguration``
- ``VaporAppLifecycleHandler``
- ``AutoRegisterRoutesConfiguration``

### Articles

- <doc:RunningAVaporApplication>
- <doc:TestingAVaporApplication>
