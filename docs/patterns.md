# Patterns

Project conventions to follow when adding code.

## Adding a view

1. Create the file under the appropriate `Views/` subfolder (e.g. `Views/Roadmap/NewView.swift`).
2. The file-system-synchronized group picks it up automatically.
3. If navigable, add the destination to the nearest `NavigationStack` /
   `navigationDestination(for:)`.
4. Depend on environment: `@Environment(FlowModel.self)` for flow state,
   `@Environment(\.modelContext)` for ad-hoc SwiftData work.
5. Use `@Query` for lists — never pass arrays through the environment.

## Adding a SwiftData field

1. Add the property to the model in `RoadmapSchemaV1.swift` **only if we
   haven't shipped yet**. Post-ship: create a V2 copy and add it there.
2. Make it optional or give it a default value. Every property must have a default.
3. If it's a relationship, declare the inverse on the related model.
4. Add a sorted accessor to `RoadmapSchemaLatest.swift` if ordering matters.

## Adding an agent stage

1. Add a `case` to the `AgentStage` enum and the `AgentStage` on the Worker.
2. New file under `roadmap-worker/src/agents/<stage>.ts` following the
   pattern of `intake.ts` — read body, fetch/update session DO, stream events.
3. Add the system prompt as `roadmap-worker/src/prompts/<stage>.md`.
4. Wire a route in `roadmap-worker/src/index.ts`.
5. Add a client method on `AgentClient` that streams `AgentEvent`s.
6. Trace the call: every model invocation emits a `trace` event that the
   client persists via `TraceLogger`.

## Adding a service

- New file under `Services/`. Default to a singleton (`static let shared`)
  with `@MainActor`. Stateless helpers can be plain structs.
- If it talks to the network, inject a protocol so tests can fake it. The
  existing `AgentClient` / `SessionStore` pair is the template.

## Navigation

Top-level flow: `FlowModel.phase` switches between `onboarding`, `generating`,
and `ready`. Individual screens use `NavigationStack` with
`navigationDestination(for: UUID.self)` — destinations are resolved by the
screen that owns the data.

## Scheduling

`ScheduleEngine(daysPerWeek:startDate:).assignDates(to:)` assigns
`scheduledDate` in-memory. Caller is responsible for saving the context.
Use the same engine for the initial generation and for re-scheduling after a
weekly revision.

## Streaks

`StreakEngine(now:).summary(for:)` is pure. Computed from task
`completedAt` values; no persisted streak state — source of truth is the
completion log.

## Calendar

`AddToCalendarSheet` wraps `EKEventEditViewController` and imports from
`EventKitUI`. Presenting this sheet does **not** trigger a calendar
permission prompt — iOS handles consent itself. Never call
`EKEventStore.requestAccess` anywhere in this project.

## Build & run

```sh
# XcodeBuildMCP session-first flow:
session_show_defaults          # verify project/scheme/sim are set
build_run_sim                  # build, install, launch on default sim
test_sim                       # run the Swift Testing suite
```

For the Worker:

```sh
cd roadmap-worker
npm install
npx wrangler kv namespace create RESOURCE_CACHE   # once, paste ID into wrangler.toml
cp .dev.vars.example .dev.vars                    # fill ANTHROPIC_API_KEY
npx wrangler dev                                  # local
npx wrangler deploy                               # ship
```
