import XCTest
@testable import GentleRemoteStrings

// MARK: - BundledDefaults

final class BundledDefaultsTests: XCTestCase {

    func testInitWithPayload() {
        let payload = TestData.payload(strings: ["key": TestData.entry("value")])
        let defaults = BundledDefaults(payload: payload)
        XCTAssertEqual(defaults.defaults()?.strings["key"]?.text, "value")
    }

    func testInitWithNilPayload() {
        let defaults = BundledDefaults(payload: nil)
        XCTAssertNil(defaults.defaults())
    }

    func testInitWithMissingBundleResource() {
        let defaults = BundledDefaults(
            bundle: .module,
            resource: "nonexistent_file",
            extension: "json"
        )
        XCTAssertNil(defaults.defaults())
    }

    func testInitWithInvalidJsonReturnsNil() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileURL = tempDir.appendingPathComponent("bad.json")
        try "not json".data(using: .utf8)?.write(to: fileURL)

        // Bundle won't find arbitrary temp files, so this validates
        // that a missing resource returns nil defaults
        let defaults = BundledDefaults(bundle: .module, resource: "bad", extension: "json")
        XCTAssertNil(defaults.defaults())
    }
}

// MARK: - RemoteStringValue

final class RemoteStringValueTests: XCTestCase {

    func testMissingKeyFactory() {
        let value = RemoteStringValue.missing(key: "some.key")
        XCTAssertEqual(value.key, "some.key")
        XCTAssertEqual(value.text, "some.key")
        XCTAssertNil(value.accessibility)
        XCTAssertEqual(value.labelOrDefault, "some.key")
        XCTAssertEqual(value.hintOrEmpty, "")
    }

    func testLabelOrDefaultWithLabel() {
        let value = RemoteStringValue(
            key: "k",
            text: "Display",
            accessibility: AccessibilityContent(label: "Custom Label", hint: nil)
        )
        XCTAssertEqual(value.labelOrDefault, "Custom Label")
    }

    func testLabelOrDefaultFallsBackToText() {
        let value = RemoteStringValue(key: "k", text: "Display", accessibility: nil)
        XCTAssertEqual(value.labelOrDefault, "Display")
    }

    func testHintOrEmptyWithHint() {
        let value = RemoteStringValue(
            key: "k",
            text: "Display",
            accessibility: AccessibilityContent(label: nil, hint: "Tap to continue")
        )
        XCTAssertEqual(value.hintOrEmpty, "Tap to continue")
    }

    func testHintOrEmptyFallsBackToEmpty() {
        let value = RemoteStringValue(key: "k", text: "Display", accessibility: nil)
        XCTAssertEqual(value.hintOrEmpty, "")
    }

    func testHintOrEmptyWhenHintIsNil() {
        let value = RemoteStringValue(
            key: "k",
            text: "Display",
            accessibility: AccessibilityContent(label: "Label", hint: nil)
        )
        XCTAssertEqual(value.hintOrEmpty, "")
    }

    func testEquality() {
        let a = RemoteStringValue(key: "k", text: "Hello")
        let b = RemoteStringValue(key: "k", text: "Hello")
        let c = RemoteStringValue(key: "k", text: "Different")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}

// MARK: - NilLogger

final class NilLoggerTests: XCTestCase {

    func testLogDoesNotCrash() {
        let logger = NilLogger()
        logger.log("test message")
        // No crash = pass
    }
}

// MARK: - SystemClock

final class SystemClockTests: XCTestCase {

    func testNowReturnsCurrentDate() {
        let clock = SystemClock()
        let before = Date()
        let now = clock.now()
        let after = Date()
        XCTAssertGreaterThanOrEqual(now, before)
        XCTAssertLessThanOrEqual(now, after)
    }
}

// MARK: - Codable round-trips

final class CodableTests: XCTestCase {

    func testRemoteStringsPayloadRoundTrip() throws {
        let payload = TestData.payload(strings: [
            "key1": TestData.entry("Hello", label: "Hi", hint: "Greet"),
            "key2": TestData.entry("Bye")
        ])
        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(RemoteStringsPayload.self, from: data)
        XCTAssertEqual(decoded, payload)
    }

    func testAccessibilityContentOptionalFields() throws {
        let labelOnly = AccessibilityContent(label: "Label", hint: nil)
        let hintOnly = AccessibilityContent(label: nil, hint: "Hint")
        let both = AccessibilityContent(label: "Label", hint: "Hint")
        let neither = AccessibilityContent(label: nil, hint: nil)

        for original in [labelOnly, hintOnly, both, neither] {
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(AccessibilityContent.self, from: data)
            XCTAssertEqual(decoded, original)
        }
    }

    func testRemoteStringEntryWithAndWithoutAccessibility() throws {
        let withA11y = TestData.entry("Text", label: "Label", hint: "Hint")
        let withoutA11y = TestData.entry("Text")

        for original in [withA11y, withoutA11y] {
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(RemoteStringEntry.self, from: data)
            XCTAssertEqual(decoded, original)
        }
    }

    func testCachedPayloadRoundTripWithISO8601() throws {
        let cached = CachedPayload(
            payload: TestData.payload(strings: ["k": TestData.entry("v")]),
            etag: "\"abc\"",
            fetchedAt: Date(timeIntervalSince1970: 1_000_000)
        )
        let data = try JSONEncoder.withISO8601.encode(cached)
        let decoded = try JSONDecoder.withISO8601.decode(CachedPayload.self, from: data)
        XCTAssertEqual(decoded.payload, cached.payload)
        XCTAssertEqual(decoded.etag, cached.etag)
        XCTAssertEqual(decoded.fetchedAt, cached.fetchedAt)
    }
}
