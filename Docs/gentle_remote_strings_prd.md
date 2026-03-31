# Product Requirements Document (PRD)
## GentleRemoteStrings

### 1. Overview
GentleRemoteStrings is a lightweight remote strings system with a Swift client and Python backend. Its purpose is to let apps fetch user-facing copy and accessibility metadata from a remote service while preserving strong local fallback behavior, high testability, and low architectural lock-in.

The system is intentionally **not** a feature flag platform and should avoid the operational complexity that usually comes with remote config systems. The product should stay narrow in scope: **remote strings and related accessibility text**, delivered in a way that is easy to understand, easy to test, and easy to replace.

---

### 2. Problem Statement
Mobile teams often need to update text after an app release for:
- copy improvements
- accessibility refinements
- typo fixes
- legal or compliance wording adjustments
- low-risk UX experimentation without shipping a full binary update

Existing solutions often create problems:
- too much vendor lock-in
- SDKs with hidden global state or singleton usage
- weak testability
- heavy buy-in to one remote config model
- poor startup performance
- systems that expand from strings into fragile all-purpose runtime configuration

GentleRemoteStrings should provide a narrow, clean solution that gives teams remote text flexibility **without turning into a full remote config platform**.

---

### 3. Product Goals
#### Primary goals
- Deliver remote text and accessibility metadata to Swift applications.
- Support a backend that is simple to deploy to Python hosting providers such as Render.
- Preserve strong local fallback behavior so the app remains usable offline or during outages.
- Make the Swift client highly testable through protocol-oriented design and dependency injection.
- Avoid hard buy-in so teams can replace the backend or the client implementation with minimal friction.
- Keep the architecture small enough for one engineer to understand end-to-end.

#### Secondary goals
- Demonstrate staff-level architecture thinking around API design, fallback strategy, caching, and deployment simplicity.
- Provide a polished open-source example of Swift + Python interoperability.
- Show how accessibility content can be treated as a first-class concern rather than an afterthought.

#### Non-goals
- Full feature flagging
- arbitrary remote config
- audience targeting or experimentation platform behavior
- analytics pipeline ownership
- CMS/editor UI in v1
- auth-heavy enterprise management portal in v1

---

### 4. Target Users
#### Primary users
- iOS engineers who want a lightweight remote strings solution
- teams maintaining apps that need low-risk text updates
- teams that care about accessibility labels and hints as first-class remote content

#### Secondary users
- engineering leads evaluating architecture quality
- hiring managers/reviewers assessing backend-leaning mobile design work
- developers who want an alternative to large remote config SDKs

---

### 5. Core Product Principles
1. **Narrow scope wins**  
   Strings only, with accessibility metadata. Do not drift into general remote config.

2. **Local-first resilience**  
   A default app experience must exist without network success.

3. **No hard buy-in**  
   Consumers should not be forced into a singleton, global container, or vendor-specific data model.

4. **Protocol-oriented design**  
   Every major Swift dependency should be abstracted behind small protocols.

5. **Testability by default**  
   All behavior should be unit testable without network access.

6. **Swapability**  
   Another backend or provider should be substitutable with minimal client changes.

7. **Deployability over cleverness**  
   The Python backend should be simple to run locally and simple to deploy to Render.

---

### 6. Product Scope
## 6.1 v1 Scope
### Swift client
- fetch remote strings payload from backend
- decode strings payload into typed Swift domain models
- support fallback chain:
  1. bundled defaults
  2. cached remote payload
  3. fresh remote payload
- expose ergonomic API for text and accessibility lookup
- inject dependencies rather than use singletons
- provide protocol-based abstractions for networking, storage, logging, clock/time, and remote provider
- support async/await
- support deterministic unit tests

### Python backend
- serve versioned JSON payload for strings
- include ETag or equivalent cache validation support
- expose health endpoint
- expose strings endpoint
- allow static or file-backed content source in v1
- run locally with minimal setup
- deploy cleanly to Render

### Shared contract
- stable JSON schema for strings + accessibility metadata
- version field for future migrations
- metadata fields for timestamps and optional locale/app version targeting hooks

## 6.2 Possible v2 Scope
- locale support beyond a single base locale
- admin/update endpoint protected by auth
- dashboard or internal editing UI
- staged rollout by app version
- namespace segmentation by screen or module
- tooling to validate missing keys against bundled defaults

---

### 7. Functional Requirements
## 7.1 Swift Client Requirements
### FR-1: Fetch remote strings payload
The client must be able to request a remote strings document from a configurable endpoint.

### FR-2: Parse structured strings data
The client must decode payloads containing:
- string key
- display text
- accessibility label
- accessibility hint
- optional metadata

### FR-3: Support fallback lookup
For any requested key, the client must resolve using a predictable fallback strategy.

Proposed lookup strategy:
1. use fresh remote payload if available
2. else use cached payload if available
3. else use bundled default
4. else return safe missing-key placeholder or empty metadata depending on API surface

### FR-4: Expose ergonomic consumer API
The client should support usage patterns similar to:
- `remote("checkout.continue").text`
- `remote("checkout.continue").a11y.labelOrDefault`
- `remote("checkout.continue").a11y.hintOrEmpty`

### FR-5: Avoid global state
The client must not require singleton usage, static service locators, or hidden global caches.

### FR-6: Dependency injection
Consumers must be able to inject:
- transport client
- storage/cache
- remote provider
- base URL / endpoint config
- fallback defaults provider
- logging strategy
- clock/time provider

### FR-7: Support provider replacement
The core lookup layer should depend on a provider protocol so the app can swap to:
- another backend
- another payload format adapter
- a local-only implementation
- a mock provider for tests

### FR-8: Cache remote payload locally
The client must be able to persist the last successful payload and associated metadata such as ETag and fetch timestamp.

### FR-9: Conditional refresh
The client should support conditional fetch behavior using ETag or equivalent validation headers where available.

### FR-10: Async refresh control
The client should support explicit refresh behavior rather than forcing a fetch during every lookup.

### FR-11: Deterministic testing
The client must be fully unit testable with fake network, fake cache, and fake time abstractions.

## 7.2 Python Backend Requirements
### FR-12: Serve strings payload
Backend must expose an HTTP endpoint returning a JSON document of strings and metadata.

### FR-13: Return cache metadata
Backend should return ETag and cache-related headers to support efficient client refresh behavior.

### FR-14: Health check endpoint
Backend must expose a simple health endpoint for deployment verification.

### FR-15: Simple content source
Backend v1 should be able to serve from a version-controlled JSON file or equivalent simple source.

### FR-16: Minimal deployment complexity
Backend must be runnable using common Python tooling and easy to deploy to Render.

### FR-17: Stable contract
Backend must preserve a stable schema version so Swift clients can safely parse and validate responses.

---

### 8. Non-Functional Requirements
## 8.1 Architecture
- Swift code should emphasize small, composable protocols.
- Domain logic should be separate from transport and persistence details.
- No UIKit or SwiftUI coupling in the core package.
- The package should be usable from UIKit, SwiftUI, and test targets.

## 8.2 Performance
- String lookup should be in-memory and fast after load.
- Network fetch should not block app startup by default.
- Cached payload loading should be lightweight.
- Payload size target should remain small, ideally tens of KB in v1.

## 8.3 Reliability
- App behavior must remain safe during backend downtime.
- Invalid remote payloads must fail safely and preserve last known good state.
- The client should never leave the app with fewer strings than bundled defaults.

## 8.4 Security
- v1 may be public-read if intended for demo/open-source simplicity.
- No secrets should be embedded in the client for basic read access.
- If write/update APIs are added later, they must require authentication.

## 8.5 Maintainability
- Backend should be understandable by a mobile engineer with moderate Python familiarity.
- Public Swift API should remain small and explicit.
- JSON schema changes should be versioned.

---

### 9. Proposed User Experience
## 9.1 App developer experience
The consuming app should be able to:
1. define bundled default strings
2. initialize a remote strings service with injected dependencies
3. load cached content on app launch if desired
4. refresh content in the background at suitable lifecycle moments
5. read values with an ergonomic lookup API

## 9.2 End-user experience
End users should experience:
- correct text even when offline
- updated copy after refresh without full SDK complexity
- improved accessibility labels/hints when remote content changes
- no regressions during backend outages

---

### 10. API / Data Contract
## 10.1 Example response shape
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
    },
    "profile.logout": {
      "text": "Log Out",
      "accessibility": {
        "label": "Log out",
        "hint": "Signs you out of your account"
      }
    }
  }
}
```

## 10.2 Response headers
Preferred support:
- `ETag`
- `Cache-Control`
- optional `Last-Modified`

## 10.3 Endpoint proposal
- `GET /health`
- `GET /v1/strings`

Optional future:
- `GET /v1/strings?locale=en-US`
- `GET /v1/strings?appVersion=1.4.0`

---

### 11. Swift Architecture Proposal
## 11.1 Suggested package layers
### Core domain
- `RemoteStringEntry`
- `AccessibilityContent`
- `RemoteStringsPayload`
- `RemoteStringValue`

### Protocols
- `RemoteStringsProviding`
- `RemoteStringsFetching`
- `RemoteStringsCaching`
- `DefaultsProviding`
- `DateProviding` or `ClockProviding`
- `RemoteStringsLogging`

### Services
- `RemoteStringsService`
- `RemoteStringsRefresher`
- `RemoteStringsResolver`

### Infrastructure adapters
- `URLSessionHTTPClient`
- `FileCacheStore`
- `JSONPayloadDecoder`

## 11.2 Design expectations
- Constructor injection over property injection where possible
- No singleton shared instances
- No hidden static mutable state
- Public interfaces should be protocol-backed where substitution matters
- Keep the top-level consumer API small and friendly

## 11.3 Example dependency shape
The main service might depend on:
- fetcher
- cache
- defaults provider
- logger
- clock

This lets tests supply fakes for every dependency and lets consuming apps swap implementations easily.

---

### 12. Backend Architecture Proposal
## 12.1 Suggested stack
- Python 3.11+
- FastAPI or Flask
- Uvicorn or Gunicorn for serving
- JSON file as source-of-truth in v1

FastAPI is slightly preferred for:
- simple JSON APIs
- clean typing/storytelling
- easy local dev
- straightforward Render deployment

## 12.2 Content model
v1 content can live in a checked-in JSON file such as:
- `content/en-US.json`

The backend reads this file, validates schema, computes ETag, and serves it.

## 12.3 Deployment expectations
The backend should include:
- `requirements.txt` or `pyproject.toml`
- `render.yaml` or clear Render setup instructions
- local run instructions
- health check route

## 12.4 Operational posture
- low traffic expected in demo/open-source mode
- stateless service preferred
- no database required in v1
- simple file-backed deployment is acceptable and desirable

---

### 13. Testing Requirements
## 13.1 Swift tests
Must include unit tests for:
- fallback ordering
- cache hit/miss behavior
- decoding valid payloads
- handling invalid payloads
- ETag/conditional refresh behavior
- missing key behavior
- accessibility fallback behavior
- provider swapability

Optional later:
- integration tests with a local stub server

## 13.2 Python tests
Must include tests for:
- health endpoint
- strings endpoint
- JSON schema validation
- ETag generation / conditional requests
- invalid file handling

---

### 14. Success Criteria
## 14.1 Technical success
- Swift package works without singleton/global state
- client can run entirely with mocked dependencies in tests
- backend deploys successfully to Render with minimal configuration
- app can serve strings from bundled defaults, cached data, and fresh remote data
- client API remains small and not vendor-locked

## 14.2 Portfolio success
- repository demonstrates thoughtful mobile architecture plus pragmatic backend design
- README clearly explains tradeoffs and why this is intentionally not feature flags
- project looks realistic enough to discuss in interviews as a production-minded design

---

### 15. Risks and Mitigations
#### Risk: Scope creep into remote config
Mitigation: Keep schema limited to text and accessibility metadata only.

#### Risk: Startup performance regressions
Mitigation: Do not require blocking network fetch on app launch.

#### Risk: Invalid remote payload breaks copy
Mitigation: Validate payload and retain last known good cache plus bundled defaults.

#### Risk: Too much architecture for a small project
Mitigation: Keep protocols small and only abstract true seams.

#### Risk: Hosting cold starts on free tiers like Render
Mitigation: Ensure local defaults and cache strategy prevent user-visible issues.

---

### 16. Open Questions
- Should v1 support only one locale, or include locale in the design from day one?
- Should app version targeting exist in schema now, even if not actively used?
- Should the public Swift API expose raw lookup only, or also typed wrappers/helpers?
- Should cached payload expiration be time-based, validation-based, or both?
- Should accessibility fields be optional or always present in normalized data?

---

### 17. Recommended v1 Decision Set
To keep momentum high, v1 should choose:
- **single locale initially**
- **FastAPI backend**
- **file-backed JSON source**
- **GET /v1/strings + GET /health**
- **ETag support**
- **async/await Swift client**
- **protocol-driven architecture with constructor injection**
- **no singleton/global state**
- **bundled defaults + cache + remote fallback chain**

---

### 18. Build Milestones
#### Milestone 1: Contract and models
- define JSON schema
- define Swift domain models
- define Python response model

#### Milestone 2: Backend MVP
- health endpoint
- strings endpoint
- file-backed content
- ETag support
- local docs + Render deploy config

#### Milestone 3: Swift client core
- protocols
- fetcher
- cache
- resolver
- public API

#### Milestone 4: Tests and sample app
- unit tests for core logic
- small demo app or sample usage
- README with architecture rationale

---

### 19. Final Product Positioning
GentleRemoteStrings should be positioned as:

> A lightweight, testable remote strings system for Swift apps, backed by a simple Python service, designed to avoid the operational and architectural complexity of full remote config platforms.

It should communicate pragmatic engineering judgment:
- clear boundaries
- resilient fallback behavior
- accessibility-first thinking
- protocol-oriented Swift architecture
- deployment simplicity
- easy replacement of both client and backend pieces

