import Foundation

/// Main entry point for consumers. Implements stale-while-revalidate:
/// - `string(for:)` returns immediately from the best available source
/// - `refresh()` fetches from the backend and updates cache in the background
///
/// Fallback order: remote (in-memory) → cached → bundled defaults → missing key placeholder
public actor RemoteStringsService: RemoteStringsProviding {
    private let fetcher: RemoteStringsFetching
    private let cache: RemoteStringsCaching
    private let defaultsProvider: DefaultsProviding
    private let logger: RemoteStringsLogging
    private let clock: ClockProviding
    private let endpoint: URL

    /// In-memory state
    private var currentPayload: RemoteStringsPayload?
    private var currentEtag: String?
    private var hasLoadedCache = false

    public init(
        endpoint: URL,
        fetcher: RemoteStringsFetching,
        cache: RemoteStringsCaching,
        defaultsProvider: DefaultsProviding,
        logger: RemoteStringsLogging = NilLogger(),
        clock: ClockProviding = SystemClock()
    ) {
        self.endpoint = endpoint
        self.fetcher = fetcher
        self.cache = cache
        self.defaultsProvider = defaultsProvider
        self.logger = logger
        self.clock = clock
    }

    // MARK: - RemoteStringsProviding

    public func string(for key: String) async -> RemoteStringValue {
        // Ensure cache is loaded on first access
        if !hasLoadedCache {
            await loadFromCache()
        }

        // Try remote/cached payload first
        if let entry = currentPayload?.strings[key] {
            return RemoteStringValue(
                key: key,
                text: entry.text,
                accessibility: entry.accessibility
            )
        }

        // Try bundled defaults
        if let entry = defaultsProvider.defaults()?.strings[key] {
            return RemoteStringValue(
                key: key,
                text: entry.text,
                accessibility: entry.accessibility
            )
        }

        // Missing key — return key itself as placeholder
        logger.log("Missing key: \(key)")
        return .missing(key: key)
    }

    public func refresh() async {
        do {
            let result = try await fetcher.fetch(from: endpoint, etag: currentEtag)

            if result.notModified {
                logger.log("Server returned 304 — content unchanged")
                return
            }

            guard let data = result.data else {
                logger.log("Refresh returned no data")
                return
            }

            let payload = try JSONDecoder().decode(RemoteStringsPayload.self, from: data)

            // Reject unsupported schema versions
            guard payload.schemaVersion <= RemoteStringsPayload.supportedSchemaVersion else {
                logger.log("Unsupported schema version \(payload.schemaVersion) — ignoring")
                return
            }

            currentPayload = payload
            currentEtag = result.etag

            let cached = CachedPayload(
                payload: payload,
                etag: result.etag,
                fetchedAt: clock.now()
            )
            try await cache.save(cached)
            logger.log("Refreshed and cached \(payload.strings.count) strings")

        } catch {
            logger.log("Refresh failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Cache loading

    /// Load cached payload into memory. Called lazily on first `string(for:)`.
    public func loadFromCache() async {
        guard !hasLoadedCache else { return }
        hasLoadedCache = true

        if let cached = await cache.load() {
            guard cached.payload.schemaVersion <= RemoteStringsPayload.supportedSchemaVersion else {
                logger.log("Cached payload has unsupported schema version — skipping")
                return
            }
            currentPayload = cached.payload
            currentEtag = cached.etag
            logger.log("Loaded \(cached.payload.strings.count) strings from cache")
        }
    }
}
