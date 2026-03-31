import Foundation

/// Concrete fetcher using URLSession.
public struct URLSessionFetcher: RemoteStringsFetching {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch(from url: URL, etag: String?) async throws -> FetchResult {
        var request = URLRequest(url: url)
        if let etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        let responseEtag = httpResponse.value(forHTTPHeaderField: "ETag")

        if httpResponse.statusCode == 304 {
            return FetchResult(data: nil, etag: responseEtag ?? etag, notModified: true)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return FetchResult(data: data, etag: responseEtag, notModified: false)
    }
}
