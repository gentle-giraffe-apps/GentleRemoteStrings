import Foundation

/// The resolved value returned to consumers when looking up a key.
/// Provides safe accessors so callers never need to handle nil for display purposes.
public struct RemoteStringValue: Equatable, Sendable {
    /// The display text for this key.
    public let text: String

    /// The raw accessibility content, if any was provided.
    public let accessibility: AccessibilityContent?

    /// The key that was looked up (used as fallback text for missing keys).
    public let key: String

    public init(key: String, text: String, accessibility: AccessibilityContent? = nil) {
        self.key = key
        self.text = text
        self.accessibility = accessibility
    }

    // MARK: - Safe accessors

    /// Returns the accessibility label, or falls back to the display text.
    public var labelOrDefault: String {
        accessibility?.label ?? text
    }

    /// Returns the accessibility hint, or an empty string if none was provided.
    public var hintOrEmpty: String {
        accessibility?.hint ?? ""
    }

    // MARK: - Missing key factory

    /// Creates a value representing a missing key.
    /// The key itself is used as the display text (visible in dev, non-crashing in prod).
    public static func missing(key: String) -> RemoteStringValue {
        RemoteStringValue(key: key, text: key, accessibility: nil)
    }
}
