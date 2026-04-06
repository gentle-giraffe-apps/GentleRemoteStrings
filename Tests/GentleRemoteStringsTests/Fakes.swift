import Foundation
@testable import GentleRemoteStrings

// MARK: - Fake Fetcher

final class FakeFetcher: RemoteStringsFetching, @unchecked Sendable {
    var result: FetchResult?
    var error: Error?
    private(set) var lastRequestedEtag: String?

    func fetch(from url: URL, etag: String?) async throws -> FetchResult {
        lastRequestedEtag = etag
        if let error { throw error }
        guard let result else { throw URLError(.badServerResponse) }
        return result
    }
}

// MARK: - Fake Cache

final class FakeCache: RemoteStringsCaching, @unchecked Sendable {
    var stored: CachedPayload?
    private(set) var savedPayload: CachedPayload?

    func load() async -> CachedPayload? {
        stored
    }

    func save(_ cached: CachedPayload) async throws {
        savedPayload = cached
    }
}

// MARK: - Fake Defaults

struct FakeDefaults: DefaultsProviding {
    var payload: RemoteStringsPayload?

    func defaults() -> RemoteStringsPayload? {
        payload
    }
}

// MARK: - Fake Clock

struct FakeClock: ClockProviding {
    var date: Date = Date(timeIntervalSince1970: 1_000_000)

    func now() -> Date {
        date
    }
}

// MARK: - Fake Logger

final class FakeLogger: RemoteStringsLogging, @unchecked Sendable {
    private(set) var messages: [String] = []

    func log(_ message: String) {
        messages.append(message)
    }
}

// MARK: - Test Helpers

enum TestData {
    static let endpoint: URL = {
        guard let url = URL(string: "https://example.com/v1/strings") else {
            preconditionFailure("Invalid test endpoint URL")
        }
        return url
    }()

    /// The canonical test fixture loaded from Fixtures/test-strings.json.
    static let fixture: RemoteStringsPayload = {
        guard let url = Bundle.module.url(forResource: "test-strings", withExtension: "json", subdirectory: "Fixtures") else {
            preconditionFailure("Missing test fixture: Fixtures/test-strings.json")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(RemoteStringsPayload.self, from: data)
        } catch {
            preconditionFailure("Failed to load test fixture: \(error)")
        }
    }()

    /// Returns the fixture entry for the given key, or crashes if missing.
    static func fixtureEntry(_ key: String) -> RemoteStringEntry {
        guard let entry = fixture.strings[key] else {
            preconditionFailure("Missing fixture key: \(key)")
        }
        return entry
    }

    /// Returns a payload containing only the specified keys from the fixture.
    static func fixturePayload(keys: [String], schemaVersion: Int? = nil) -> RemoteStringsPayload {
        let filtered = fixture.strings.filter { keys.contains($0.key) }
        return RemoteStringsPayload(
            schemaVersion: schemaVersion ?? fixture.schemaVersion,
            locale: fixture.locale,
            generatedAt: fixture.generatedAt,
            strings: filtered
        )
    }

    static func payload(strings: [String: RemoteStringEntry] = [:], schemaVersion: Int = 1) -> RemoteStringsPayload {
        RemoteStringsPayload(
            schemaVersion: schemaVersion,
            locale: "en-US",
            generatedAt: "2026-03-31T00:00:00Z",
            strings: strings
        )
    }

    static func entry(_ text: String, label: String? = nil, hint: String? = nil) -> RemoteStringEntry {
        let a11y = (label != nil || hint != nil) ? AccessibilityContent(label: label, hint: hint) : nil
        return RemoteStringEntry(text: text, accessibility: a11y)
    }

    static func encodedPayload(_ payload: RemoteStringsPayload) -> Data {
        do {
            return try JSONEncoder().encode(payload)
        } catch {
            preconditionFailure("Failed to encode payload: \(error)")
        }
    }
}
