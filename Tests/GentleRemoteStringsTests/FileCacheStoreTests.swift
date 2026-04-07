import XCTest
@testable import GentleRemoteStrings

final class FileCacheStoreTests: XCTestCase {

    private var tempDir: URL = FileManager.default.temporaryDirectory

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    private func makePayload() -> CachedPayload {
        CachedPayload(
            payload: TestData.payload(strings: [
                "key": TestData.entry("Hello")
            ]),
            etag: "\"test-etag\"",
            fetchedAt: Date(timeIntervalSince1970: 1_000_000)
        )
    }

    // MARK: - Round-trip

    func testSaveAndLoadRoundTrip() async throws {
        let store = FileCacheStore(directory: tempDir)
        let original = makePayload()

        try await store.save(original)
        let loaded = await store.load()

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.payload, original.payload)
        XCTAssertEqual(loaded?.etag, original.etag)
        XCTAssertEqual(loaded?.fetchedAt, original.fetchedAt)
    }

    // MARK: - Load when no file exists

    func testLoadReturnsNilWhenNoFile() async {
        let store = FileCacheStore(directory: tempDir)
        let result = await store.load()
        XCTAssertNil(result)
    }

    // MARK: - Load with corrupt data

    func testLoadReturnsNilForCorruptData() async throws {
        let fileURL = tempDir.appendingPathComponent("gentle_remote_strings_cache.json")
        try "not valid json".data(using: .utf8)?.write(to: fileURL)

        let store = FileCacheStore(directory: tempDir)
        let result = await store.load()
        XCTAssertNil(result)
    }

    // MARK: - Overwrite existing cache

    func testSaveOverwritesPreviousCache() async throws {
        let store = FileCacheStore(directory: tempDir)

        let first = makePayload()
        try await store.save(first)

        let second = CachedPayload(
            payload: TestData.payload(strings: [
                "other": TestData.entry("World")
            ]),
            etag: "\"new-etag\"",
            fetchedAt: Date(timeIntervalSince1970: 2_000_000)
        )
        try await store.save(second)

        let loaded = await store.load()
        XCTAssertEqual(loaded?.etag, "\"new-etag\"")
        XCTAssertEqual(loaded?.payload.strings.count, 1)
        XCTAssertEqual(loaded?.payload.strings["other"]?.text, "World")
    }

    // MARK: - Custom filename

    func testCustomFilename() async throws {
        let store = FileCacheStore(directory: tempDir, filename: "custom_cache.json")
        try await store.save(makePayload())

        let fileExists = FileManager.default.fileExists(
            atPath: tempDir.appendingPathComponent("custom_cache.json").path
        )
        XCTAssertTrue(fileExists)
    }

    // MARK: - Default directory

    func testInitWithDefaultDirectory() {
        let store = FileCacheStore()
        // Should not crash — validates the guard-let path
        _ = store
    }

    // MARK: - Nil etag round-trip

    func testNilEtagRoundTrip() async throws {
        let store = FileCacheStore(directory: tempDir)
        let cached = CachedPayload(
            payload: TestData.payload(strings: ["k": TestData.entry("v")]),
            etag: nil,
            fetchedAt: Date(timeIntervalSince1970: 1_000_000)
        )

        try await store.save(cached)
        let loaded = await store.load()

        XCTAssertNotNil(loaded)
        XCTAssertNil(loaded?.etag)
    }
}
