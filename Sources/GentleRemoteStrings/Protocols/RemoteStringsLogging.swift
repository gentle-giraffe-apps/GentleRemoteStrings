import Foundation

/// Logging abstraction so consumers can plug in their own logger.
public protocol RemoteStringsLogging: Sendable {
    func log(_ message: String)
}

/// Default no-op logger.
public struct NilLogger: RemoteStringsLogging, Sendable {
    public init() {}
    public func log(_ message: String) {}
}
