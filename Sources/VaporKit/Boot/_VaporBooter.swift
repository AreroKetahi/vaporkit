//
//  _VaporBooter.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 13/07/2026
//

import ArgumentParser
import Vapor
import Configuration
import ConsoleLogger

struct _VaporBooter<App: VaporApplication>: AsyncParsableCommand {
    @ArgumentParser::Argument(parsing: .captureForPassthrough)
    var arguments: [String] = []

    @ArgumentParser::Option(name: [.short, .long])
    var environment: _VaporBooterEnvironment?

    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "run")
    }

    func run() async throws {
        let configReader = ConfigReader(providers: [
            CommandLineArgumentsProvider(arguments: ["run"] + arguments)
        ] + App.manifest.configReaderManifest.configProviders)
        ConsoleLogger.bootstrapWithConfigReader(config: configReader)

        let env: Vapor::Environment = if let environment {
            switch environment {
            case .development: .development
            case .production: .production
            case .testing: .testing
            }
        } else {
            try Environment.detect(from: configReader)
        }

        let application = try Application(
            env,
            configuration: App.manifest.serverConfiguration,
            configReader: configReader,
            services: App.manifest.serviceConfiguration
        )
        try await App.manifest._configure(application)
        App.manifest._installLifecycleHandlers(on: application)
        try await application.start()
    }
}

enum _VaporBooterEnvironment: String, CaseIterable, ExpressibleByArgument {
    case production = "prod"
    case development = "dev"
    case testing = "test"
    
    static let allValueStrings: [String] = Self.allCases.map(\.rawValue)
    
    static let defaultCompletionKind: CompletionKind = .list(allValueStrings)
    
    init?(argument: String) {
        switch argument {
        case "prod", "production":
            self = .production
        case "dev", "development":
            self = .development
        case "test", "testing":
            self = .testing
        default:
            return nil
        }
    }
}
