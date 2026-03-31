import Foundation

/// A single entry in the remote strings payload.
/// Maps to one key in the `strings` dictionary.
public struct RemoteStringEntry: Codable, Equatable, Sendable {
    public let text: String
    public let accessibility: AccessibilityContent?

    public init(text: String, accessibility: AccessibilityContent? = nil) {
        self.text = text
        self.accessibility = accessibility
    }
}
