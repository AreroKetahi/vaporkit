//
//  VaporApplication.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 13/07/2026
//

import ArgumentParser

/// A declarative entry point for a Vapor application.
///
/// Use `VaporApplication` to describe an application's startup configuration
/// with a ``VaporAppManifest``. The default command starts the Vapor server.
/// Arguments that don't select another subcommand pass through to Vapor for
/// ConsoleKit to interpret.
///
/// ```swift
/// @main
/// struct MyServer: VaporApplication {
///     static let manifest = VaporAppManifest(
///         configurations: [ServerConfiguration()]
///     )
/// }
/// ```
public protocol VaporApplication: AsyncParsableCommand {
    /// The configuration and lifecycle stages used by the application.
    static var manifest: VaporAppManifest { get }

    /// Additional Argument Parser commands exposed by the executable.
    ///
    /// Custom commands run independently of the default server command. They
    /// don't create a Vapor `Application` unless their implementation does so.
    static var subcommands: [any ParsableCommand.Type] { get }

    /// The executable name shown by Argument Parser.
    static var commandName: String { get }

    /// A one-line description of the application command.
    static var abstract: String { get }

    /// A detailed description shown in extended help.
    static var discussion: String { get }

    /// The version reported by the application's `--version` option.
    static var version: String { get }
}

public extension VaporApplication {
    /// The additional commands exposed by the application.
    ///
    /// The default value is an empty array.
    static var subcommands: [any ParsableCommand.Type] { [] }

    /// The executable name derived from the application type by default.
    ///
    /// The default value is an empty string, which asks Argument Parser to
    /// derive the command name from the application type.
    static var commandName: String { "" }

    /// The application command's one-line description.
    ///
    /// The default value is an empty string.
    static var abstract: String { "" }

    /// The application command's extended description.
    ///
    /// The default value is an empty string.
    static var discussion: String { "" }

    /// The application version exposed on the command line.
    ///
    /// The default value is an empty string, which disables `--version`.
    static var version: String { "" }

    /// The command-line configuration for the application executable.
    ///
    /// VaporKit uses the server command when the invocation doesn't select an
    /// explicit subcommand.
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: Self.commandName.isEmpty ? nil : Self.commandName,
            abstract: Self.abstract,
            discussion: Self.discussion,
            version: Self.version,
            subcommands: [
                _VaporBooter<Self>.self,
                _VaporOpenAPIExtractor<Self>.self,
            ] + self.subcommands,
            defaultSubcommand: _VaporBooter<Self>.self
        )
    }
}
