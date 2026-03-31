import Foundation

/// Cached payload with associated metadata.
public struct CachedPayload: Codable, Sendable {
    public let payload: RemoteStringsPayload
    public let etag: String?
    public let fetchedAt: Date

    public init(payload: RemoteStringsPayload, etag: String?, fetchedAt: Date) {
        self.payload = payload
        self.etag = etag
        self.fetchedAt = fetchedAt
    }
}

/// Abstracts local persistence of the remote strings payload.
public protocol RemoteStringsCaching: Sendable {
    func load() async -> CachedPayload?
    func save(_ cached: CachedPayload) async throws
}
