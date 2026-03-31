import Foundation

/// The main consumer-facing protocol for looking up remote strings.
public protocol RemoteStringsProviding: Sendable {
    /// Look up a string by key. Returns immediately from the best available source.
    func string(for key: String) async -> RemoteStringValue

    /// Trigger a background refresh. Stale-while-revalidate: callers get current data
    /// immediately; the next lookup after refresh completes will reflect any updates.
    func refresh() async
}
