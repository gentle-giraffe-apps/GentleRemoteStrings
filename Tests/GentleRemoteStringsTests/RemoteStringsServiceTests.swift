import XCTest
@testable import GentleRemoteStrings

final class RemoteStringsServiceTests: XCTestCase {

    private func makeService(
        fetcher: FakeFetcher = FakeFetcher(),
        cache: FakeCache = FakeCache(),
        defaults: FakeDefaults = FakeDefaults(),
        logger: FakeLogger = FakeLogger(),
        clock: FakeClock = FakeClock()
    ) -> (RemoteStringsService, FakeFetcher, FakeCache, FakeLogger) {
        let service = RemoteStringsService(
            endpoint: TestData.endpoint,
            fetcher: fetcher,
            cache: cache,
            defaultsProvider: defaults,
            logger: logger,
            clock: clock
        )
        return (service, fetcher, cache, logger)
    }

    // MARK: - Missing key

    func testMissingKeyReturnsKeyAsPlaceholder() async {
        let (service, _, _, _) = makeService()
        let value = await service.string(for: "unknown.key")
        XCTAssertEqual(value.text, "unknown.key")
        XCTAssertEqual(value.key, "unknown.key")
    }

    // MARK: - Bundled defaults fallback

    func testFallsBackToBundledDefaults() async {
        let defaults = FakeDefaults(payload: TestData.payload(strings: [
            "greeting": TestData.entry("Hello")
        ]))
        let (service, _, _, _) = makeService(defaults: defaults)
        let value = await service.string(for: "greeting")
        XCTAssertEqual(value.text, "Hello")
    }

    // MARK: - Cache fallback

    func testLoadsFromCacheOnFirstAccess() async {
        let cache = FakeCache()
        cache.stored = CachedPayload(
            payload: TestData.payload(strings: [
                "cached.key": TestData.entry("Cached Value")
            ]),
            etag: "\"abc\"",
            fetchedAt: Date()
        )
        let (service, _, _, _) = makeService(cache: cache)
        let value = await service.string(for: "cached.key")
        XCTAssertEqual(value.text, "Cached Value")
    }

    // MARK: - Cache beats defaults

    func testCachedPayloadTakesPrecedenceOverDefaults() async {
        let defaults = FakeDefaults(payload: TestData.payload(strings: [
            "key": TestData.entry("Default")
        ]))
        let cache = FakeCache()
        cache.stored = CachedPayload(
            payload: TestData.payload(strings: [
                "key": TestData.entry("Cached")
            ]),
            etag: nil,
            fetchedAt: Date()
        )
        let (service, _, _, _) = makeService(cache: cache, defaults: defaults)
        let value = await service.string(for: "key")
        XCTAssertEqual(value.text, "Cached")
    }

    // MARK: - Refresh

    func testRefreshUpdatesInMemoryPayload() async {
        let fetcher = FakeFetcher()
        let remotePayload = TestData.payload(strings: [
            "remote.key": TestData.entry("Remote Value")
        ])
        fetcher.result = FetchResult(
            data: TestData.encodedPayload(remotePayload),
            etag: "\"new\"",
            notModified: false
        )
        let (service, _, cache, _) = makeService(fetcher: fetcher)

        await service.refresh()

        let value = await service.string(for: "remote.key")
        XCTAssertEqual(value.text, "Remote Value")
        XCTAssertNotNil(cache.savedPayload)
    }

    func testRefreshSavesToCache() async {
        let fetcher = FakeFetcher()
        let remotePayload = TestData.payload(strings: [
            "key": TestData.entry("Value")
        ])
        fetcher.result = FetchResult(
            data: TestData.encodedPayload(remotePayload),
            etag: "\"etag1\"",
            notModified: false
        )
        let (service, _, cache, _) = makeService(fetcher: fetcher)

        await service.refresh()

        XCTAssertNotNil(cache.savedPayload)
        XCTAssertEqual(cache.savedPayload?.etag, "\"etag1\"")
        XCTAssertEqual(cache.savedPayload?.payload.strings.count, 1)
    }

    // MARK: - ETag / conditional refresh

    func testRefreshSendsEtagFromCache() async {
        let cache = FakeCache()
        cache.stored = CachedPayload(
            payload: TestData.payload(strings: ["k": TestData.entry("v")]),
            etag: "\"cached-etag\"",
            fetchedAt: Date()
        )
        let fetcher = FakeFetcher()
        fetcher.result = FetchResult(data: nil, etag: "\"cached-etag\"", notModified: true)

        let (service, _, _, _) = makeService(fetcher: fetcher, cache: cache)

        // Force cache load
        _ = await service.string(for: "k")
        await service.refresh()

        XCTAssertEqual(fetcher.lastRequestedEtag, "\"cached-etag\"")
    }

    func test304DoesNotChangePayload() async {
        let cache = FakeCache()
        cache.stored = CachedPayload(
            payload: TestData.payload(strings: ["k": TestData.entry("Original")]),
            etag: "\"etag\"",
            fetchedAt: Date()
        )
        let fetcher = FakeFetcher()
        fetcher.result = FetchResult(data: nil, etag: "\"etag\"", notModified: true)

        let (service, _, savedCache, _) = makeService(fetcher: fetcher, cache: cache)

        _ = await service.string(for: "k")
        await service.refresh()

        let value = await service.string(for: "k")
        XCTAssertEqual(value.text, "Original")
        XCTAssertNil(savedCache.savedPayload) // Nothing new saved
    }

    // MARK: - Refresh failure is safe

    func testRefreshFailurePreservesExistingPayload() async {
        let cache = FakeCache()
        cache.stored = CachedPayload(
            payload: TestData.payload(strings: ["k": TestData.entry("Cached")]),
            etag: nil,
            fetchedAt: Date()
        )
        let fetcher = FakeFetcher()
        fetcher.error = URLError(.notConnectedToInternet)

        let (service, _, _, _) = makeService(fetcher: fetcher, cache: cache)

        _ = await service.string(for: "k")
        await service.refresh()

        let value = await service.string(for: "k")
        XCTAssertEqual(value.text, "Cached")
    }

    // MARK: - Unsupported schema version

    func testRejectsUnsupportedSchemaVersion() async {
        let fetcher = FakeFetcher()
        let futurePayload = TestData.payload(
            strings: ["k": TestData.entry("Future")],
            schemaVersion: 99
        )
        fetcher.result = FetchResult(
            data: TestData.encodedPayload(futurePayload),
            etag: nil,
            notModified: false
        )
        let defaults = FakeDefaults(payload: TestData.payload(strings: [
            "k": TestData.entry("Default")
        ]))
        let (service, _, _, logger) = makeService(fetcher: fetcher, defaults: defaults)

        await service.refresh()

        let value = await service.string(for: "k")
        XCTAssertEqual(value.text, "Default")
        XCTAssertTrue(logger.messages.contains { $0.contains("Unsupported schema version") })
    }

    func testRejectsCachedPayloadWithUnsupportedSchema() async {
        let cache = FakeCache()
        cache.stored = CachedPayload(
            payload: TestData.payload(strings: ["k": TestData.entry("Old")], schemaVersion: 99),
            etag: nil,
            fetchedAt: Date()
        )
        let defaults = FakeDefaults(payload: TestData.payload(strings: [
            "k": TestData.entry("Default")
        ]))
        let (service, _, _, _) = makeService(cache: cache, defaults: defaults)

        let value = await service.string(for: "k")
        XCTAssertEqual(value.text, "Default")
    }

    // MARK: - Accessibility

    func testAccessibilityLabelOrDefault() async {
        let fetcher = FakeFetcher()
        let payload = TestData.payload(strings: [
            "with_a11y": TestData.entry("Button", label: "Tap the button", hint: "Does a thing"),
            "no_a11y": TestData.entry("Plain Text")
        ])
        fetcher.result = FetchResult(
            data: TestData.encodedPayload(payload),
            etag: nil,
            notModified: false
        )
        let (service, _, _, _) = makeService(fetcher: fetcher)
        await service.refresh()

        let with = await service.string(for: "with_a11y")
        XCTAssertEqual(with.labelOrDefault, "Tap the button")
        XCTAssertEqual(with.hintOrEmpty, "Does a thing")

        let without = await service.string(for: "no_a11y")
        XCTAssertEqual(without.labelOrDefault, "Plain Text") // falls back to text
        XCTAssertEqual(without.hintOrEmpty, "")
    }

    // MARK: - Remote beats cache beats defaults

    func testFullFallbackChainPriority() async {
        let defaults = FakeDefaults(payload: TestData.payload(strings: [
            "key": TestData.entry("Default"),
            "only_default": TestData.entry("Only In Defaults")
        ]))
        let cache = FakeCache()
        cache.stored = CachedPayload(
            payload: TestData.payload(strings: [
                "key": TestData.entry("Cached")
            ]),
            etag: nil,
            fetchedAt: Date()
        )
        let fetcher = FakeFetcher()
        let remotePayload = TestData.payload(strings: [
            "key": TestData.entry("Remote")
        ])
        fetcher.result = FetchResult(
            data: TestData.encodedPayload(remotePayload),
            etag: nil,
            notModified: false
        )

        let (service, _, _, _) = makeService(fetcher: fetcher, cache: cache, defaults: defaults)

        // Before refresh: cache wins over defaults
        let beforeRefresh = await service.string(for: "key")
        XCTAssertEqual(beforeRefresh.text, "Cached")

        // After refresh: remote wins
        await service.refresh()
        let afterRefresh = await service.string(for: "key")
        XCTAssertEqual(afterRefresh.text, "Remote")

        // Key only in defaults still accessible
        let defaultOnly = await service.string(for: "only_default")
        XCTAssertEqual(defaultOnly.text, "Only In Defaults")

        // Key in neither → missing placeholder
        let missing = await service.string(for: "nonexistent")
        XCTAssertEqual(missing.text, "nonexistent")
    }
}
