import Testing
import Vapor
import VaporTesting
@testable import VaporKit

private struct VaporApplicationFixture: VaporApplication {
    static let manifest = VaporAppManifest()
}

private struct ConfiguredVaporApplicationFixture: VaporApplication {
    static let manifest = VaporAppManifest()
    static let commandName = "fixture-server"
    static let abstract = "Fixture abstract."
    static let discussion = "Fixture discussion."
    static let version = "2.1.0"
}

@Suite struct VaporApplicationTests {
    @Test func defaultsToServerBootCommand() throws {
        let command = try VaporApplicationFixture.parseAsRoot([])
        #expect(command is _VaporBooter<VaporApplicationFixture>)
    }

    @Test func forwardsUnknownServerArguments() throws {
        let command = try VaporApplicationFixture.parseAsRoot([
            "--env", "testing",
            "serve", "--hostname", "127.0.0.1",
        ])
        let booter = try #require(command as? _VaporBooter<VaporApplicationFixture>)
        #expect(booter.arguments == [
            "--env", "testing",
            "serve", "--hostname", "127.0.0.1",
        ])
    }

    @Test func recognizesHiddenOpenAPICommand() throws {
        let command = try VaporApplicationFixture.parseAsRoot([
            "extract-openapi", "--title", "Test API",
        ])
        #expect(command is _VaporOpenAPIExtractor<VaporApplicationFixture>)
    }

    @Test func appliesApplicationCommandMetadata() {
        let configuration = ConfiguredVaporApplicationFixture.configuration
        #expect(configuration.commandName == "fixture-server")
        #expect(configuration.abstract == "Fixture abstract.")
        #expect(configuration.discussion == "Fixture discussion.")
        #expect(configuration.version == "2.1.0")
    }

    @Test func manifestExecutesLifecycleInOrder() async throws {
        try await withApp { application in
            let recorder = LifecycleRecorder()
            let manifest = VaporAppManifest(
                configurations: [RecordedConfiguration(recorder: recorder)],
                lifecycleHandlers: [
                    FirstLifecycle(recorder: recorder),
                    SecondLifecycle(recorder: recorder),
                ]
            )
            
            try await manifest._configure(application)
            manifest._installLifecycleHandlers(on: application)
            try await application.boot()
            try await application.shutdown()
            
            #expect(await recorder.events == [
                "configure",
                "first.willBoot", "second.willBoot",
                "first.didBoot", "second.didBoot",
                "second.shutdown", "first.shutdown",
            ])
        }
    }
}

private actor LifecycleRecorder {
    private(set) var events: [String] = []

    func record(_ event: String) {
        events.append(event)
    }
}

private struct RecordedConfiguration: VaporAppConfiguration {
    let recorder: LifecycleRecorder

    func configure(_ application: Application) async throws {
        await recorder.record("configure")
    }
}

private struct FirstLifecycle: VaporAppLifecycleHandler {
    let recorder: LifecycleRecorder

    func willBoot(_ application: Application) async throws {
        await recorder.record("first.willBoot")
    }

    func didBoot(_ application: Application) async throws {
        await recorder.record("first.didBoot")
    }

    func shutdown(_ application: Application) async {
        await recorder.record("first.shutdown")
    }
}

private struct SecondLifecycle: VaporAppLifecycleHandler {
    let recorder: LifecycleRecorder

    func willBoot(_ application: Application) async throws {
        await recorder.record("second.willBoot")
    }

    func didBoot(_ application: Application) async throws {
        await recorder.record("second.didBoot")
    }

    func shutdown(_ application: Application) async {
        await recorder.record("second.shutdown")
    }
}
