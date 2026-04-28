# FoodoTest

## Setup & Run
1. Clone the repo and open `FoodoTestApp.xcodeproj` in Xcode 15+.
2. Select a simulator running iOS 16+.
3. Build & Run (⌘R). No extra setup needed — the app uses JSONPlaceholder as a public API.
4. Run tests: ⌘U (or Product → Test).

## Architecture Overview

**Pattern:** MVVM with a Repository layer as single source of truth.


- **Model** — Plain Swift structs (`Item`, `LiveEvent`). Codable + CoreData mappers.
- **Persistence** — Wraps `NSPersistentContainer`. Background contexts for writes.
- **APIClient** — Protocol-based; real impl hits JSONPlaceholder, `MockAPIClient` used in tests.
- **ItemRepository** — Orchestrates fetch → merge → persist → publish. The only place that touches CoreData.
- **ViewModel** — `@MainActor` ObservableObjects. Consume `itemsPublisher` via Combine.
- **View** — Pure SwiftUI. No business logic.

## Key Decisions

### Offline Strategy
- On every successful fetch the data is upserted into CoreData.
- On launch/refresh, if `NetworkMonitor` reports offline, the ViewModel reads cache directly without hitting the network.
- An orange banner indicates offline mode on both list and detail screens.

### Cache Invalidation (TTL + updatedAt merge)
Two layers:
1. **TTL (5 minutes):** `isCacheStale()` lets callers skip network when data is fresh.
2. **`updatedAt` comparison:** During merge, a remote or event item only overwrites an existing record when its `updatedAt` is strictly newer. This prevents stale events from downgrading fresh data.

### Live Updates (Option B — Local Event Stream)
- `mock_events.json` bundles a list of `LiveEvent` objects.
- A `Timer` in `ItemListViewModel` fires every 10 seconds and emits the next event.
- `ItemRepository.applyEvent()` applies the event in a background CoreData context.
- Diff is identity-based (`id`); SwiftUI `.animation(.easeInOut, value: items)` handles smooth list updates.

### Concurrency
- All CoreData writes use `newBackgroundContext()` + `ctx.perform { }`.
- ViewModels are `@MainActor`; repository publishes back to main via `.receive(on: DispatchQueue.main)`.

## What I Would Improve With More Time
- **Pagination** for large datasets.
- **Search & filter** on the list screen.
- **Conflict resolution UI** when a background update affects the currently open detail screen.
- **Keychain-backed auth** if the API requires tokens.
- **UI tests** with `XCUITest` for the offline banner and empty state.
- **Snapshot tests** for `StatusBadgeView` and `ItemRowView`.
- **More granular error types** surfaced to the user (e.g., distinguishing timeout vs. server error).
- Replace `Timer`-based polling with `AsyncStream` for cleaner backpressure.

## Third-Party Libraries
None. The app uses only Apple frameworks (SwiftUI, CoreData, Combine, Network).
