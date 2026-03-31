import Foundation

/// The top-level response from the remote strings backend.
public struct RemoteStringsPayload: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let locale: String
    public let generatedAt: String
    public let strings: [String: RemoteStringEntry]

    public init(
        schemaVersion: Int,
        locale: String,
        generatedAt: String,
        strings: [String: RemoteStringEntry]
    ) {
        self.schemaVersion = schemaVersion
        self.locale = locale
        self.generatedAt = generatedAt
        self.strings = strings
    }

    /// The maximum schema version this client can decode.
    public static let supportedSchemaVersion = 1
}
