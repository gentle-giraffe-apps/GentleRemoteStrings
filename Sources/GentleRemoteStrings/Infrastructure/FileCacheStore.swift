import Foundation

/// Persists cached payloads to a JSON file on disk.
public struct FileCacheStore: RemoteStringsCaching {
    private let fileURL: URL

    public init(directory: URL? = nil, filename: String = "gentle_remote_strings_cache.json") {
        let dir = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.fileURL = dir.appendingPathComponent(filename)
    }

    public func load() async -> CachedPayload? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder.withISO8601.decode(CachedPayload.self, from: data)
    }

    public func save(_ cached: CachedPayload) async throws {
        let data = try JSONEncoder.withISO8601.encode(cached)
        try data.write(to: fileURL, options: .atomic)
    }
}

extension JSONDecoder {
    static let withISO8601: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

extension JSONEncoder {
    static let withISO8601: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
