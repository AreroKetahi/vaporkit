//
//  _VaporOpenAPIExtractor.swift
//  vaporkit
//
//  Created by Arkivili Collindort on 13/07/2026
//

import ArgumentParser
import Foundation

struct _VaporOpenAPIExtractor<App: VaporApplication>: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "extract-openapi",
            abstract: "Exports linked OpenAPI metadata (Alpha).",
            discussion: """
                This command and its corresponding functionality are still in alpha quality, 
                and no promises are made about robustness and ABI stability. 
                By using this command, you agree and accept any side effects and circumstances 
                caused by using unstable functions.
                """
        )
    }

    @ArgumentParser::Option(name: .long)
    var title = "API"

    @ArgumentParser::Option(name: .long)
    var version = "1.0.0"

    @ArgumentParser::Option(name: [.customShort("o"), .long])
    var output: String?

    @ArgumentParser::Flag(help: "Print the OpenAPI document to standard output.")
    var inline = false

    mutating func validate() throws {
        guard (output != nil) != inline else {
            throw ValidationError("Specify exactly one of '--inline' or '--output/-o'.")
        }
    }

    func run() async throws {
        let descriptors = _OpenAPIDiscovery.discover()
        guard !descriptors.isEmpty else {
            throw ValidationError("No OpenAPI router metadata was discovered in this executable.")
        }

        if inline {
            print(String(decoding: try OpenAPIExporter.data(
                title: title,
                version: version,
                descriptors: descriptors
            ), as: UTF8.self))
            return
        }

        guard let output else {
            throw ValidationError("Specify exactly one of '--inline' or '--output/-o'.")
        }
        let workingDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        var outputURL = URL(fileURLWithPath: output, relativeTo: workingDirectory).standardizedFileURL
        if outputURL.pathExtension.lowercased() != "json" {
            outputURL.appendPathExtension("json")
        }
        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try OpenAPIExporter.export(
            to: outputURL,
            title: title,
            version: version,
            descriptors: descriptors
        )
    }
}
