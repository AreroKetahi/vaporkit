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
            abstract: "Exports linked OpenAPI metadata (Alpha)."
        )
    }

    @ArgumentParser.Option(name: .long)
    var title = "API"

    @ArgumentParser.Option(name: .long)
    var version = "1.0.0"

    @ArgumentParser.Option(name: [.customShort("o"), .long])
    var output = "openapi.json"

    func run() async throws {
        let descriptors = _OpenAPIDiscovery.discover()
        guard !descriptors.isEmpty else {
            throw ValidationError("No OpenAPI router metadata was discovered in this executable.")
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
