import Foundation

/// Loads bundled default strings from a JSON file in the app bundle.
public struct BundledDefaults: DefaultsProviding {
    private let payload: RemoteStringsPayload?

    public init(bundle: Bundle = .main, resource: String = "defaults", extension ext: String = "json") {
        guard let url = bundle.url(forResource: resource, withExtension: ext),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(RemoteStringsPayload.self, from: data) else {
            self.payload = nil
            return
        }
        self.payload = decoded
    }

    /// Initialize with an explicit payload (useful for testing or programmatic defaults).
    public init(payload: RemoteStringsPayload?) {
        self.payload = payload
    }

    public func defaults() -> RemoteStringsPayload? {
        payload
    }
}
