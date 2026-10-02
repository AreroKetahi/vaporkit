# Migrating the Application Entry Point

Replace the Vapor template entry point with ``VaporApplication``.

## Overview

Move the body of the template's `configure(_:)` function into a
``VaporAppConfiguration`` value:

```swift
struct AppSetup: VaporAppConfiguration {
    func configure(_ application: Application) async throws {
        application.middleware.use(FileMiddleware(
            publicDirectory: application.directory.publicDirectory
        ))
        try await application.register(collection: UserRoutes())
    }
}
```

Then replace the template's `Entrypoint.main()` with one `@main` type:

```swift
@main
struct MyServer: VaporApplication {
    static let manifest = VaporAppManifest(
        configurations: [AppSetup()]
    )
}
```

Running the executable without an explicit subcommand starts Vapor. The `run`
subcommand starts the same server explicitly:

```sh
swift run Server
swift run Server run --environment production --hostname 0.0.0.0 --port 8080
```

`--environment` (or `-e`) is handled by the server command and accepts
`dev`/`development`, `prod`/`production`, and `test`/`testing`. Put it before
passthrough arguments. Remaining arguments become configuration values for
Vapor through `CommandLineArgumentsProvider`, rather than ConsoleKit commands.
For example, `--hostname` and `--port` configure the listening address.

Without an explicit environment option, Vapor reads `vapor.env` from the
configuration reader:

```sh
swift run Server run --vapor.env production --port 8080
VAPOR_ENV=production swift run Server
```

When migrating from Vapor 4, remove the old `serve` command from invocations.

### Add Startup Features

Add ``AutoRegisterRoutesConfiguration`` to the manifest when routers use
automatic discovery. Add ``VaporAppLifecycleHandler`` values for work tied to
boot and shutdown rather than configuration.

```swift
static let manifest = VaporAppManifest(
    configurations: [
        AppSetup(),
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
