//
//  _VaporBooter.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 13/07/2026
//

import ArgumentParser
import Vapor

struct _VaporBooter<App: VaporApplication>: AsyncParsableCommand {
    @ArgumentParser.Argument(parsing: .captureForPassthrough)
    var arguments: [String] = []

    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "server")
    }

    func run() async throws {
        var environment = try Environment.detect()
        environment.commandInput.arguments = arguments
        try LoggingSystem.bootstrap(from: &environment)

        let application = try await Application.make(environment)
        try await _runVaporBootSequence(
            configure: { try await App.manifest.configure(application) },
            willBoot: { try await App.manifest.willBoot(application) },
            boot: { try await application.asyncBoot() },
            didBoot: { try await App.manifest.didBoot(application) },
            execute: { try await application.execute() },
            manifestShutdown: { try await App.manifest.shutdown(application) },
            applicationShutdown: { try await application.asyncShutdown() },
            report: { application.logger.report(error: $0) }
        )
    }
}

func _runVaporBootSequence(
    configure: () async throws -> Void,
    willBoot: () async throws -> Void,
    boot: () async throws -> Void,
    didBoot: () async throws -> Void,
    execute: () async throws -> Void,
    manifestShutdown: () async throws -> Void,
    applicationShutdown: () async throws -> Void,
    report: (any Error) -> Void
) async throws {
    var enteredManifestLifecycle = false
    var primaryError: (any Error)?

    do {
        try await configure()
        enteredManifestLifecycle = true
        try await willBoot()
        try await boot()
        try await didBoot()
        try await execute()
    } catch {
        report(error)
        primaryError = error
    }

    if enteredManifestLifecycle {
        do {
            try await manifestShutdown()
        } catch {
            report(error)
            if primaryError == nil { primaryError = error }
        }
    }

    do {
        try await applicationShutdown()
    } catch {
        report(error)
        if primaryError == nil { primaryError = error }
    }

    if let primaryError { throw primaryError }
}
