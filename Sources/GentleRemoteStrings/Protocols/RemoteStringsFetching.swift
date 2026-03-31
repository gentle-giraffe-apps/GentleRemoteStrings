import Foundation

/// Result of a remote fetch, including optional ETag for conditional requests.
public struct FetchResult: Sendable {
    public let data: Data?
    public let etag: String?
    public let notModified: Bool

    public init(data: Data?, etag: String?, notModified: Bool) {
        self.data = data
        self.etag = etag
        self.notModified = notModified
    }
}

/// Abstracts the network transport for fetching remote strings.
public protocol RemoteStringsFetching: Sendable {
    /// Fetch strings from the given URL, optionally sending an ETag for conditional validation.
    func fetch(from url: URL, etag: String?) async throws -> FetchResult
}
