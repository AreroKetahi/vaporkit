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
        configurations: [ServerConfiguration()],
        lifecycleHandlers: [ServerLifecycle()]
    )
}
```

### Configuring the Application

Add ``VaporAppConfiguration`` values to the manifest in the order they should
configure the application. VaporKit runs all configuration stages before boot.

```swift
struct ServerConfiguration: VaporAppConfiguration {
    func configure(_ application: Application) async throws {
        application.middleware.use(FileMiddleware(
            publicDirectory: application.directory.publicDirectory
        ))
        try application.autoRegisterRouters()
    }
}
```

### Observing the Lifecycle

Add ``VaporAppLifecycleHandler`` values for boot and shutdown work. Boot
callbacks run in declaration order; shutdown callbacks run in reverse order.

```swift
struct ServerLifecycle: VaporAppLifecycleHandler {
    func didBoot(_ application: Application) async throws {
        application.logger.info("Server started")
    }

    func shutdown(_ application: Application) async throws {
        application.logger.info("Server stopped")
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

### Startup and Lifecycle

- ``VaporAppConfiguration``
- ``VaporAppLifecycleHandler``
- ``AutoRegisterRoutesConfiguration``

### Articles

- <doc:RunningAVaporApplication>
