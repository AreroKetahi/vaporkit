import Foundation
import Testing
import VaporKit

@Suite struct VaporKitOpenAPIExtractorTests {
    @Test func applicationExecutableExportsOpenAPI() throws {
        let fixture = try DynamicOpenAPIFixture.prepare()
        let serverURL = try fixture.buildServerExecutable()
        let requestedOutputURL = fixture.outputURL.deletingPathExtension()
        if FileManager.default.fileExists(atPath: fixture.outputURL.path) {
            try FileManager.default.removeItem(at: fixture.outputURL)
        }

        let result = try fixture.run(serverURL, arguments: [
            "extract-openapi",
            "--title", "Fixture API",
            "--version", "2.0.0",
            "--output", requestedOutputURL.path,
        ])

        #expect(result.status == 0, Comment(rawValue: result.output))
        let data = try Data(contentsOf: fixture.outputURL)
        let document = try JSONDecoder().decode(OpenAPIDocument.self, from: data)
        #expect(document.info.title == "Fixture API")
        #expect(document.info.version == "2.0.0")
        let publicUser = try #require(
            document.paths["/api/v1/users/{id}"]?["get"]
        )
        #expect(publicUser.summary == "Get a fixture user")
        #expect(publicUser.tags == ["Users"])
        #expect(publicUser.parameters?.map(\.name) == ["id", "include.profile", "filter"])
        #expect(publicUser.parameters?.last?.schema.type == .object)
        #expect(publicUser.responses["200"]?.content?["application/json"]?.schema.type == .object)
        #expect(document.paths["/api/admin/users/{id}"]?["get"] != nil)
        #expect(
            document.paths["/api/v1/users"]?["post"]?
                .responses["201"]?.content?["application/json"]?.schema.type == .object
        )
        #expect(
            document.paths["/api/v1/users"]?["post"]?
                .requestBody?.content["application/json"]?.schema.type == .object
        )
        #expect(
            document.paths["/api/health"]?["get"]?
                .responses["200"]?.content?["application/json"]?.schema.type == .string
        )
        #expect(
            document.paths["/api/preview"]?["post"]?
                .requestBody?.required == false
        )
        #expect(document.paths["/api/v1/users/internal"] == nil)
    }
}

private struct DynamicOpenAPIFixture {
    struct ProcessResult {
        let status: Int32
        let output: String
    }

    let packageURL: URL
    let repositoryURL: URL
    let scratchURL: URL
    let outputURL: URL

    static func prepare() throws -> Self {
        let repositoryURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let root = repositoryURL.appending(path: ".build/openapi-extractor-tests")
        let packageURL = root.appending(path: "package")
        let sourcesURL = packageURL.appending(path: "Sources/AppServer")
        let outputURL = root.appending(path: "output/openapi.json")

        try FileManager.default.createDirectory(
            at: sourcesURL,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        try writeIfChanged(
            packageManifest(repositoryURL: repositoryURL),
            to: packageURL.appending(path: "Package.swift")
        )
        try writeIfChanged(
            fixtureSource,
            to: sourcesURL.appending(path: "Routes.swift")
        )

        return Self(
            packageURL: packageURL,
            repositoryURL: repositoryURL,
            scratchURL: root.appending(path: "scratch"),
            outputURL: outputURL
        )
    }

    func run(_ executable: URL, arguments: [String]) throws -> ProcessResult {
        guard FileManager.default.isExecutableFile(atPath: executable.path) else {
            throw FixtureError.missingBinaryPath
        }
        return try execute(executable, arguments: arguments)
    }

    func buildServerExecutable() throws -> URL {
        #if os(macOS)
        let swiftExecutable = URL(fileURLWithPath: "/usr/bin/xcrun")
        let swiftArguments = ["swift"]
        #else
        let swiftExecutable = URL(fileURLWithPath: "/usr/bin/env")
        let swiftArguments = ["swift"]
        #endif

        let build = try execute(
            swiftExecutable,
            arguments: swiftArguments + [
                "build",
                "--package-path", packageURL.path,
                "--scratch-path", scratchURL.path,
                "--product", "AppServer",
            ]
        )
        guard build.status == 0 else { throw FixtureError.commandFailed(build.output) }
        let binPath = try execute(
            swiftExecutable,
            arguments: swiftArguments + [
                "build",
                "--package-path", packageURL.path,
                "--scratch-path", scratchURL.path,
                "--show-bin-path",
            ]
        )
        guard binPath.status == 0 else { throw FixtureError.commandFailed(binPath.output) }
        let directory = binPath.output.split(whereSeparator: \.isNewline).last.map(String.init) ?? ""
        return URL(fileURLWithPath: directory).appending(path: "AppServer")
    }

    private func execute(_ executable: URL, arguments: [String]) throws -> ProcessResult {
        let logURL = scratchURL
            .deletingLastPathComponent()
            .appending(path: "process.log")
        try FileManager.default.createDirectory(
            at: logURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        _ = FileManager.default.createFile(atPath: logURL.path, contents: nil)
        let log = try FileHandle(forWritingTo: logURL)
        defer { try? log.close() }

        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = log
        process.standardError = log
        try process.run()
        process.waitUntilExit()
        try log.synchronize()

        let data = try Data(contentsOf: logURL)
        return ProcessResult(
            status: process.terminationStatus,
            output: String(decoding: data, as: UTF8.self)
        )
    }

    private static func writeIfChanged(_ content: String, to url: URL) throws {
        let data = Data(content.utf8)
        if (try? Data(contentsOf: url)) == data { return }
        try data.write(to: url, options: .atomic)
    }

    private static func packageManifest(repositoryURL: URL) -> String {
        """
        // swift-tools-version: 6.3

        import PackageDescription

        let package = Package(
            name: "OpenAPIFixture",
            platforms: [.macOS(.v14)],
            products: [
                .executable(name: "AppServer", targets: ["AppServer"])
            ],
            dependencies: [
                .package(path: \(String(reflecting: repositoryURL.path)))
            ],
            targets: [
                .executableTarget(
                    name: "AppServer",
                    dependencies: [
                        .product(
                            name: "VaporKit",
                            package: \(String(reflecting: repositoryURL.lastPathComponent))
                        ),
                    ],
                    path: "Sources/AppServer"
                )
            ]
        )
        """
    }

    private static let fixtureSource = #"""
    import Foundation
    import VaporKit

    @Router("api")
    struct FixtureRootRouter {
        #Get("health") { _ -> String in
            "ok"
        }

        @OpenAPIRequest(body: CreateFixtureUser.self, required: false)
        #Post("preview") { _ -> FixtureUser in
            FixtureUser(id: UUID(), name: "preview", nickname: nil, scores: [])
        }

        #Register(FixtureV1Router(), FixtureAdminRouter())
    }

    @Router("v1")
    struct FixtureV1Router {
        #Register(FixtureUsersRouter())
    }

    @Router("admin")
    struct FixtureAdminRouter {
        #Register(FixtureUsersRouter())
    }

    @OpenAPISchema
    struct FixtureUser: Content {
        var id: UUID
        var name: String
        var nickname: String?
        var scores: [Int]
    }

    @OpenAPISchema
    struct CreateFixtureUser: Content {
        var name: String
        var nickname: String?
    }

    @OpenAPISchema
    struct FixtureFilter: Codable {
        var active: Bool
    }

    @Router("users")
    struct FixtureUsersRouter {
        @OpenAPI(
            summary: "Get a fixture user",
            description: "Returns a user from the dynamically compiled fixture.",
            tags: ["Users"]
        )
        @OpenAPIResponse(body: FixtureUser.self)
        @Get(":id")
        func user(
            _ request: Request,
            @Path id: UUID,
            @Query("include.profile") includeProfile: Bool?,
            @Query filter: FixtureFilter
        ) async throws -> FixtureUser {
            FixtureUser(
                id: id,
                name: request.method.rawValue,
                nickname: includeProfile == true ? "fixture" : nil,
                scores: [1, 2, 3]
            )
        }

        @OpenAPIResponse(.created)
        @Post
        func create(
            _ request: Request,
            @ContentBody body: CreateFixtureUser
        ) async throws -> FixtureUser {
            FixtureUser(
                id: UUID(),
                name: body.name,
                nickname: body.nickname,
                scores: []
            )
        }

        @OpenAPIIgnored
        @Get("internal")
        func internalRoute(_ request: Request) async throws -> String {
            request.url.path
        }
    }

    @main
    struct FixtureApplication: VaporApplication {
        static let manifest = VaporAppManifest()
    }
    """#

    private enum FixtureError: Error {
        case commandFailed(String)
        case missingBinaryPath
    }
}
