# GentleRemoteStrings

A lightweight, testable remote strings system for Swift apps, backed by a simple Python service. Designed to avoid the operational and architectural complexity of full remote config platforms.

## Why This Exists

Mobile teams need to update text after release — copy improvements, accessibility refinements, typo fixes, legal wording. Existing solutions tend to bring too much: vendor lock-in, hidden global state, poor testability, and scope creep into general remote config.

GentleRemoteStrings stays narrow on purpose: **remote strings and accessibility metadata**, nothing more.

## What This Is Not

- Not a feature flag system
- Not a general remote config platform
- Not an experimentation or targeting engine

## Architecture

### Swift Client

Protocol-oriented with constructor injection. No singletons, no global state.

```
┌─────────────────────────────────────────────┐
│           RemoteStringsService              │
│  (actor, stale-while-revalidate)            │
├─────────────────────────────────────────────┤
│ RemoteStringsFetching  │ Network transport  │
│ RemoteStringsCaching   │ Local persistence  │
│ DefaultsProviding      │ Bundled fallbacks  │
│ ClockProviding         │ Deterministic time │
│ RemoteStringsLogging   │ Pluggable logging  │
└─────────────────────────────────────────────┘
```

**Fallback chain** (stale-while-revalidate):
1. Return best available immediately (remote in-memory or cached) — never blocks the caller
2. Background refresh with ETag/If-None-Match
3. If remote and cache are empty, fall back to bundled defaults
4. If key is missing everywhere, return the key itself as a placeholder

**Every dependency is injectable and swappable.** Tests run with fake network, fake cache, and fake time — no network access needed.

### Python Backend

FastAPI serving strings from a version-controlled JSON file. Stateless, no database.

- `GET /health` — deployment verification
- `GET /v1/strings` — returns strings payload with ETag support
- 304 Not Modified on conditional requests
- Validates content against Pydantic models on every request

## Quick Start

### Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Endpoints:
- http://localhost:8000/health
- http://localhost:8000/v1/strings

### Swift Client

Add the package dependency:

```swift
.package(url: "https://github.com/your-org/GentleRemoteStrings.git", from: "1.0.0")
```

Wire up with injected dependencies:

```swift
let service = RemoteStringsService(
    endpoint: URL(string: "https://your-backend.com/v1/strings")!,
    fetcher: URLSessionFetcher(),
    cache: FileCacheStore(),
    defaultsProvider: BundledDefaults(payload: yourDefaults)
)

// Look up strings — returns immediately from cache/defaults
let value = await service.string(for: "checkout.continue")
value.text              // "Continue"
value.labelOrDefault    // "Continue to payment"
value.hintOrEmpty       // "Navigates to the payment step"

// Refresh in background — next lookup gets fresh data
await service.refresh()
```

See `Example/` for full SwiftUI integration patterns.

## JSON Contract

```json
{
  "schemaVersion": 1,
  "locale": "en-US",
  "generatedAt": "2026-03-31T00:00:00Z",
  "strings": {
    "checkout.continue": {
      "text": "Continue",
      "accessibility": {
        "label": "Continue to payment",
        "hint": "Navigates to the payment step"
      }
    }
  }
}
```

- `accessibility` is optional per entry
- `label` and `hint` are each optional within `accessibility`
- `schemaVersion` is validated by the client — unknown versions are safely ignored

## Testing

### Swift

```bash
swift test
```

13 unit tests covering: fallback ordering, cache hit/miss, ETag conditional refresh, 304 handling, missing keys, accessibility safe defaults, unsupported schema rejection, refresh failure safety.

### Python

```bash
cd backend
python -m pytest tests/ -v
```

9 tests covering: health endpoint, strings endpoint, ETag generation, conditional 304, cache headers, optional accessibility, error handling for missing/invalid content.

## Deploy to Render

The backend includes a `render.yaml` for one-click deployment:

1. Connect your repo to Render
2. Render auto-detects `render.yaml`
3. Health check at `/health` is pre-configured

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Strings only, no feature flags | Scope discipline — avoids becoming another remote config platform |
| Accessibility as first-class content | Labels and hints deserve the same remote-update flexibility as display text |
| Stale-while-revalidate | UI strings should never block rendering; one-session-behind is acceptable |
| ETag validation, no TTL | Simple cache invalidation without clock dependencies in the cache layer |
| Missing key returns the key itself | Visible during development, non-crashing in production |
| Actor-based service | Thread-safe by construction in Swift concurrency |
| No singletons | Consumers own their instances; testable without global teardown |

## Project Structure

```
├── Sources/GentleRemoteStrings/
│   ├── Models/              # Domain types
│   ├── Protocols/           # Dependency abstractions
│   ├── Infrastructure/      # Concrete implementations
│   └── Services/            # RemoteStringsService
├── Tests/GentleRemoteStringsTests/
├── Example/                 # SwiftUI integration samples
├── backend/
│   ├── app/                 # FastAPI application
│   ├── content/             # JSON string files
│   ├── tests/               # Python tests
│   ├── requirements.txt
│   └── render.yaml
└── Docs/                    # PRD
```

## License

See [LICENSE](LICENSE) for details.
