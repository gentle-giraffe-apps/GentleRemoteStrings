import Foundation

/// Abstracts the system clock for deterministic testing.
public protocol ClockProviding: Sendable {
    func now() -> Date
}

/// Default implementation using the system clock.
public struct SystemClock: ClockProviding, Sendable {
    public init() {}

    public func now() -> Date {
        Date()
    }
}
