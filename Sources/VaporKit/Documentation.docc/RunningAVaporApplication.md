# Migrating the Application Entry Point

Replace the Vapor template entry point with ``VaporApplication``.

## Overview

Move the body of the template's `configure(_:)` function into a
``VaporAppConfiguration`` value:

```swift
struct ServerConfiguration: VaporAppConfiguration {
    func configure(_ application: Application) async throws {
        application.middleware.use(FileMiddleware(
            publicDirectory: application.directory.publicDirectory
        ))
        try routes(application)
    }
}
```

Then replace the template's `Entrypoint.main()` with one `@main` type:

```swift
@main
struct MyServer: VaporApplication {
    static let manifest = VaporAppManifest(
        configurations: [ServerConfiguration()]
    )
}
```

Running the executable without an explicit subcommand starts Vapor. Existing
Vapor and ConsoleKit server arguments keep their behavior.

### Add Startup Features

Add ``AutoRegisterRoutesConfiguration`` to the manifest when routers use
automatic discovery. Add ``VaporAppLifecycleHandler`` values for work tied to
boot and shutdown rather than configuration.

```swift
static let manifest = VaporAppManifest(
    configurations: [
        ServerConfiguration(),
        AutoRegisterRoutesConfiguration.default,
    ],
    lifecycleHandlers: [ServerLifecycle()]
)
```

Configuration and boot callbacks run in declaration order; shutdown callbacks
run in reverse order. See <doc:ApplicationEntryPoint> for the lifecycle model.

### Add Independent Commands

Expose ArgumentParser commands through ``VaporApplication/subcommands``.
VaporKit chooses a command before creating the application, so an independent
command doesn't run server configuration unless it creates an application
itself.

```swift
static let subcommands: [any ParsableCommand.Type] = [Diagnose.self]
```

## Topics

### Entry-Point APIs

- ``VaporApplication``
- ``VaporAppManifest``
- ``VaporAppConfiguration``
- ``VaporAppLifecycleHandler``
- ``AutoRegisterRoutesConfiguration``
