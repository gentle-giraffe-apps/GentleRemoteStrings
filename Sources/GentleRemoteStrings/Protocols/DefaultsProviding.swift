import Foundation

/// Provides bundled default strings as a fallback when remote and cache are unavailable.
public protocol DefaultsProviding: Sendable {
    func defaults() -> RemoteStringsPayload?
}
