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
        return result!
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
    static let endpoint = URL(string: "https://example.com/v1/strings")!

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
        try! JSONEncoder().encode(payload)
    }
}
