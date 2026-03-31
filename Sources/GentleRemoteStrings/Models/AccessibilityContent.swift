import Foundation

/// Accessibility metadata for a remote string entry.
/// Optional in the JSON schema — the client provides safe defaults when absent.
public struct AccessibilityContent: Codable, Equatable, Sendable {
    public let label: String?
    public let hint: String?

    public init(label: String? = nil, hint: String? = nil) {
        self.label = label
        self.hint = hint
    }
}
