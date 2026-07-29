# BlockTalk iOS — Claude Code Guide

## Project Overview

BlockTalk is a hyper-local social app for NYC neighborhoods. SwiftUI app targeting iOS 17+, backed by Supabase (Postgres + Auth + Storage). No mock data — everything reads from and writes to the live Supabase database.

## Architecture

- **Models**: `BlockTalk/Models/` — Codable structs matching Supabase table schemas
- **Services**: `BlockTalk/Services/` — thin wrappers around `supabase.from(...)` calls. All data comes from the real database
- **ViewModels**: `BlockTalk/ViewModels/` — `@Observable` classes that call services
- **Views**: `BlockTalk/Views/` — SwiftUI views organized by tab (Feed, Map, Discover, You) plus Detail, Modals, Onboarding, Splash
- **AppState**: `BlockTalk/App/AppState.swift` — single `@Observable` source of truth for auth, navigation, and neighborhood state

## Critical Rules

### No Mock Data

All data must come from Supabase. Never generate fake/mock/sample/placeholder data in production code paths. If a query fails, show an empty state or an error — never fall back to hardcoded content.

- `PostService` fetches posts from the `posts` table
- `ReplyService` fetches replies from the `replies` table
- `NeighborhoodService` fetches neighborhoods from the `neighborhoods` table
- `DiscoverViewModel` fetches trending posts and active neighborhoods via Supabase queries and RPCs
- The only local data source is `NeighborhoodDirectory` (bundled list of all ~280 NYC neighborhoods used for the picker UI and polygon rendering — this is reference data, not mock data)

### Database Relationships

PostgREST (Supabase) has an ambiguous FK between `users` and `posts`/`replies` because the `enrollments` table also references `users`. Always disambiguate joins:

```swift
// CORRECT — specify the FK name
"*, author:users!posts_user_id_fkey(username, user_number, home:neighborhoods(short_code))"
"*, author:users!replies_user_id_fkey(username, user_number, home:neighborhoods(short_code))"

// WRONG — will cause PGRST201 error
"*, author:users(username, user_number, home:neighborhoods(short_code))"
```

### Neighborhood Resolution

The app resolves which neighborhood the user is in through a fallback chain. Never assume any single source is available:

1. `postingNeighborhood` — explicitly passed (pin posts)
2. `locationService.currentNeighborhood` — GPS-resolved (requires location permission)
3. `appState.currentUser?.homeNeighborhoodId` — from user profile in DB
4. `appState.viewingNeighborhood` — always set after onboarding

In the simulator, location is typically denied, so fallbacks 3 and 4 are critical.

### Supabase Client

The global `supabase` client is configured in `BlockTalk/App/Supabase.swift`. Auth uses Sign in with Apple. The Supabase project URL and anon key are in that file.

## Project Generation

This project uses **xcodegen** with `project.yml` as the source of truth. After modifying `project.yml`:

```bash
xcodegen generate
```

Important settings in `project.yml`:
- `DEVELOPMENT_TEAM: YUQATHNGE2` — do NOT remove this
- `BlockTalkTests` target exists for unit tests

## File Patterns

| Pattern | Convention |
|---------|-----------|
| New service | Add to `BlockTalk/Services/`, use `supabase.from(...)` |
| New view model | Add to `BlockTalk/ViewModels/`, use `@Observable` |
| New view | Add to appropriate `BlockTalk/Views/` subdirectory |
| New Supabase migration | Add to `Supabase/` with incrementing prefix (`00005_...`) |
| Tests | Add to `BlockTalkTests/`, use `@testable import BlockTalk` |

## Testing

```bash
xcodebuild test \
  -scheme BlockTalk \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:BlockTalkTests
```

~119 unit tests covering pure synchronous logic (language check, models, view model validation, reply tree building, app state). No network calls in tests.

## Debug / Testing Features

`SettingsTestingView.swift` is wrapped in `#if DEBUG` and provides:
- Delete user & reset onboarding (calls `delete_user_and_data` RPC)
- Debug panel showing current user state
- Only visible in debug builds

## Before Every Commit

Always run the full test suite before committing any changes. Do not commit if tests fail.

```bash
xcodebuild test \
  -scheme BlockTalk \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:BlockTalkTests
```

If any test fails, fix the issue before committing. Never skip or delete a failing test to make a commit pass.

## Adding Seed / Test Data

If you need sample data for development or testing (sample posts, users, neighborhoods, etc.), never hardcode it in Swift. Instead, add a new SQL migration script in `Supabase/` with the next incrementing prefix (e.g., `00005_seed_sample_posts.sql`). Run it via the Supabase SQL Editor. This keeps test data in the database where the app naturally reads from, and makes it easy to add or remove without touching app code.

## Common Pitfalls

1. **Don't add fake "talking" counts or activity numbers** — if the backend doesn't have the data yet, leave it out rather than generating numbers from hashes or random seeds
2. **Don't remove `DEVELOPMENT_TEAM`** from `project.yml` — it breaks code signing
3. **Neighborhood IDs**: The local `NeighborhoodDirectory` uses synthetic UUIDs. Real Supabase IDs are resolved via `NeighborhoodService.fetchByName()` before saving to the database. Never persist a synthetic UUID to Supabase
4. **RLS policies**: The Supabase tables have Row Level Security. If a write silently fails (affects 0 rows), check for missing RLS policies
5. **`#Preview` blocks** use inline sample data — this is fine, it's only for Xcode previews, never shown to users

## Supabase SQL Migrations

Migrations live in `Supabase/` and should be run in the Supabase SQL Editor in order:
- `00001_initial_schema.sql` — tables, indexes, RLS, triggers
- `00002_seed_neighborhoods.sql` — initial 82 neighborhoods
- `00003_delete_user_rpc.sql` — RPC for cascading user delete
- `00004_seed_missing_neighborhoods.sql` — remaining ~188 neighborhoods
