# Gotchas

Things that'll bite if you don't know them.

## SwiftData

- **Relationships are unordered sets.** Always iterate via the `ordered…`
  extensions in `RoadmapSchemaLatest.swift`.
- **Every property needs a default or must be optional.** CloudKit won't let
  you flip sync on later without this, and migrations get simpler.
- **Saving from a background context requires its own actor isolation.** The
  app is `@MainActor` by default; only use `.background` for large batch
  imports (e.g. the agent's `handleGenerate` result).
- **`@Model` classes can't be `Sendable` or `Codable` cleanly.** Transfer
  DTOs (like `AgentTraceDTO`) and map to models on the main actor.

## xcconfig

- `//` starts a comment in xcconfig. URLs are built via the `SLASH = /`
  indirection — see `Secrets.example.xcconfig`.
- Build setting → Info.plist mapping requires the `INFOPLIST_KEY_*` prefix
  when `GENERATE_INFOPLIST_FILE = YES`. We use `INFOPLIST_KEY_RoadmapWorkerURL`.

## EventKit

- `EKEventEditViewController` is in `EventKitUI`, not `EventKit`. Both
  imports are needed in `CalendarService.swift`.
- Presenting the sheet does **not** require us to call `requestAccess`.
  iOS prompts the user during the sheet interaction if needed. Keep it
  that way — the app never takes a calendar permission itself.

## Cloudflare Worker

- The free tier's 30-second CPU ceiling will trip Sonnet generation.
  `wrangler.toml` sets `cpu_ms = 300000` and requires the $5 paid plan.
- Durable Objects need a migration on first class definition. `wrangler.toml`
  has `new_sqlite_classes = ["SessionDO"]` under `[[migrations]]`.
- KV eventual consistency (~60s) is fine for resource caching. Don't use KV
  for session state.

## Anthropic API

- Prompt caching requires `cache_control: { type: "ephemeral" }` explicitly
  on each block you want cached. System prompts almost always benefit.
- Cache hit reporting lives in `response.usage.cache_read_input_tokens`.
  Forward that as `cachedInputTokens` on every `AgentTrace`.
- Model IDs: `claude-haiku-4-5-20251001`, `claude-sonnet-4-6`,
  `claude-opus-4-7`. See `src/agents/_anthropic.ts`.

## SourceKit-LSP (standalone)

The LSP in this environment often reports "Cannot find type X in scope"
across files in the same target. `build_sim` is authoritative — trust the
compiler, not the squiggles.

## iOS 26 features

Guard any iOS-26-only API with `#available(iOS 26, *)`. The deployment
target is iOS 18.
