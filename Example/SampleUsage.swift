/// Sample usage showing how to wire up and use GentleRemoteStrings.
/// This is not a runnable app — it demonstrates the integration pattern.

import Foundation
import GentleRemoteStrings

// MARK: - 1. Define bundled defaults

/// Your app ships with a defaults.json in the bundle as a safety net.
/// Even if the backend is down and the cache is empty, text is always available.
let bundledDefaults = BundledDefaults(
    payload: RemoteStringsPayload(
        schemaVersion: 1,
        locale: "en-US",
        generatedAt: "2026-03-31T00:00:00Z",
        strings: [
            "checkout.continue": RemoteStringEntry(
                text: "Continue",
                accessibility: AccessibilityContent(
                    label: "Continue to payment",
                    hint: "Navigates to the payment step"
                )
            ),
            "profile.logout": RemoteStringEntry(
                text: "Log Out",
                accessibility: AccessibilityContent(
                    label: "Log out",
                    hint: "Signs you out of your account"
                )
            )
        ]
    )
)

// MARK: - 2. Create the service with injected dependencies

/// No singletons. No global state. You own the instance.
let stringsService: RemoteStringsService = {
    guard let endpoint = URL(string: "https://your-backend.onrender.com/v1/strings") else {
        preconditionFailure("Invalid endpoint URL")
    }
    return RemoteStringsService(
        endpoint: endpoint,
        fetcher: URLSessionFetcher(),
        cache: FileCacheStore(),
        defaultsProvider: bundledDefaults
    )
}()

// MARK: - 3. Use in your app

/// On app launch or scene activation, kick off a background refresh.
/// This doesn't block — cached or bundled values are served immediately.
func onAppLaunch() async {
    await stringsService.refresh()
}

/// Look up strings with an ergonomic API.
func exampleLookup() async {
    let continueButton = await stringsService.string(for: "checkout.continue")

    // Display text
    _ = continueButton.text                // "Continue"

    // Accessibility — safe defaults when absent
    _ = continueButton.labelOrDefault      // "Continue to payment"
    _ = continueButton.hintOrEmpty         // "Navigates to the payment step"

    // Missing keys return the key itself — visible in dev, safe in prod
    let missing = await stringsService.string(for: "nonexistent.key")
    _ = missing.text                       // "nonexistent.key"
}
