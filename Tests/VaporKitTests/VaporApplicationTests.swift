import Testing
import Vapor
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
        let application = try await Application.make(.testing)
        let manifest = VaporAppManifest(
            configurations: [RecordedConfiguration()],
            lifecycleHandlers: [FirstLifecycle(), SecondLifecycle()]
        )

        try await manifest.configure(application)
        try await manifest.willBoot(application)
        try await manifest.didBoot(application)
        try await manifest.shutdown(application)

        #expect(application.storage[LifecycleEventsKey.self] == [
            "configure",
            "first.willBoot", "second.willBoot",
            "first.didBoot", "second.didBoot",
            "second.shutdown", "first.shutdown",
        ])
        try await application.asyncShutdown()
    }

    @Test func configurationFailureDoesNotEnterManifestLifecycle() async {
        var events: [BootStage] = []
        var reported: [BootFailure] = []

        do {
            try await runBootSequence(
                failingAt: .configure,
                events: &events,
                reported: &reported
            )
            Issue.record("Expected the boot sequence to fail.")
        } catch {
            #expect(error as? BootFailure == .configure)
        }

        #expect(events == [.configure, .applicationShutdown])
        #expect(reported == [.configure])
    }

    @Test(arguments: [
        BootStage.willBoot,
        .boot,
        .didBoot,
        .execute,
    ])
    func lifecycleFailureRunsBothShutdownPhases(failingAt stage: BootStage) async {
        var events: [BootStage] = []
        var reported: [BootFailure] = []

        do {
            try await runBootSequence(
                failingAt: stage,
                events: &events,
                reported: &reported
            )
            Issue.record("Expected the boot sequence to fail.")
        } catch {
            #expect(error as? BootFailure == BootFailure(stage))
        }

        #expect(events.last == .applicationShutdown)
        #expect(events.dropLast().last == .manifestShutdown)
        #expect(reported.first == BootFailure(stage))
    }

    @Test(arguments: [
        BootStage.manifestShutdown,
        .applicationShutdown,
    ])
    func shutdownFailureIsPropagated(failingAt stage: BootStage) async {
        var events: [BootStage] = []
        var reported: [BootFailure] = []

        do {
            try await runBootSequence(
                failingAt: stage,
                events: &events,
                reported: &reported
            )
            Issue.record("Expected the boot sequence to fail.")
        } catch {
            #expect(error as? BootFailure == BootFailure(stage))
        }

        #expect(events.suffix(2) == [.manifestShutdown, .applicationShutdown])
        #expect(reported == [BootFailure(stage)])
    }

    @Test func shutdownFailuresDoNotReplaceThePrimaryFailure() async {
        var reported: [BootFailure] = []

        do {
            try await _runVaporBootSequence(
                configure: {},
                willBoot: {},
                boot: { throw BootFailure.boot },
                didBoot: {},
                execute: {},
                manifestShutdown: { throw BootFailure.manifestShutdown },
                applicationShutdown: { throw BootFailure.applicationShutdown },
                report: {
                    if let failure = $0 as? BootFailure { reported.append(failure) }
                }
            )
            Issue.record("Expected the boot sequence to fail.")
        } catch {
            #expect(error as? BootFailure == .boot)
        }

        #expect(reported == [.boot, .manifestShutdown, .applicationShutdown])
    }
}

enum BootStage: CaseIterable, Equatable, Sendable {
    case configure
    case willBoot
    case boot
    case didBoot
    case execute
    case manifestShutdown
    case applicationShutdown
}

private enum BootFailure: Error, Equatable {
    case configure
    case willBoot
    case boot
    case didBoot
    case execute
    case manifestShutdown
    case applicationShutdown

    init(_ stage: BootStage) {
        switch stage {
        case .configure: self = .configure
        case .willBoot: self = .willBoot
        case .boot: self = .boot
        case .didBoot: self = .didBoot
        case .execute: self = .execute
        case .manifestShutdown: self = .manifestShutdown
        case .applicationShutdown: self = .applicationShutdown
        }
    }
}

private func runBootSequence(
    failingAt failure: BootStage,
    events: inout [BootStage],
    reported: inout [BootFailure]
) async throws {
    func stage(_ stage: BootStage) throws {
        events.append(stage)
        if stage == failure { throw BootFailure(stage) }
    }

    try await _runVaporBootSequence(
        configure: { try stage(.configure) },
        willBoot: { try stage(.willBoot) },
        boot: { try stage(.boot) },
        didBoot: { try stage(.didBoot) },
        execute: { try stage(.execute) },
        manifestShutdown: { try stage(.manifestShutdown) },
        applicationShutdown: { try stage(.applicationShutdown) },
        report: {
            if let failure = $0 as? BootFailure { reported.append(failure) }
        }
    )
}

private struct LifecycleEventsKey: StorageKey {
    typealias Value = [String]
}

private func record(_ event: String, in application: Application) {
    var events = application.storage[LifecycleEventsKey.self] ?? []
    events.append(event)
    application.storage[LifecycleEventsKey.self] = events
}

private struct RecordedConfiguration: VaporAppConfiguration {
    func configure(_ application: Application) async throws {
        record("configure", in: application)
    }
}

private struct FirstLifecycle: VaporAppLifecycleHandler {
    func willBoot(_ application: Application) async throws {
        record("first.willBoot", in: application)
    }

    func didBoot(_ application: Application) async throws {
        record("first.didBoot", in: application)
    }

    func shutdown(_ application: Application) async throws {
        record("first.shutdown", in: application)
    }
}

private struct SecondLifecycle: VaporAppLifecycleHandler {
    func willBoot(_ application: Application) async throws {
        record("second.willBoot", in: application)
    }

    func didBoot(_ application: Application) async throws {
        record("second.didBoot", in: application)
    }

    func shutdown(_ application: Application) async throws {
        record("second.shutdown", in: application)
    }
}
