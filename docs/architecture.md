# Architecture

RoadmapApp is a SwiftUI + SwiftData iOS app backed by a Cloudflare Worker. It
takes a user's free-text learning goal, runs a multi-stage agent loop to
produce a personalized roadmap, then tracks daily practice locally.

## Layers

```
┌─────────────────────────────────────────────────────────────┐
│                        iOS app                              │
│  Views ──▶ FlowModel ──▶ Services ──▶ RoadmapStore          │
│                                              │              │
│                                              ▼              │
│                                         SwiftData           │
│                                       (on-device)           │
│                                                             │
│  AgentClient ────────────── HTTP ──────────────┐            │
└─────────────────────────────────────────────────┼───────────┘
                                                  │
                                                  ▼
┌─────────────────────────────────────────────────────────────┐
│                   Cloudflare Worker                         │
│  fetch router ──▶ per-stage handler ──▶ Anthropic API       │
│                         │                                   │
│                         ▼                                   │
│                  Durable Object (session)                   │
│                  KV (resource cache)                        │
└─────────────────────────────────────────────────────────────┘
```

## Why this split

The agent loop lives on the Worker, not the device, for four reasons:

1. **API key safety.** The Anthropic key never ships with the app.
2. **Prompt caching.** Cache hits live server-side; every client benefits.
3. **Resource cache.** Free-tier web lookups are pooled across users in KV.
4. **Course rubric.** Cleaner separation between "the agent" and "the client
   UI" makes the multi-stage pipeline easier to demonstrate.

## Data flow for first-run onboarding

1. User types a goal → `FlowModel.submitGoal()` → `SessionStore.createSession()` → Worker creates a `SessionDO`.
2. `AgentClient.runIntake()` → Worker `/v1/intake` (Haiku) → streams back the first assessment question.
3. User answers → `AgentClient.continueAssessment()` → Worker `/v1/assess` (Haiku). Loop until the model calls `finalize_assessment`.
4. `AgentClient.runGenerate()` → Worker `/v1/generate` (Sonnet) → streams the roadmap JSON.
5. Client decodes, inserts into `RoadmapStore`, activates it, assigns schedule dates via `ScheduleEngine`.
6. `FlowModel.phase = .ready` → `MainTabView` shown.

Every Worker call writes an `AgentTrace` row on the client for audit/demo.

## Data flow for daily use

- `TodayView` queries tasks with `scheduledDate` in today's range.
- Toggling completion updates `completedAt` and triggers a `StreakEngine` refresh on the Weekly Review screen.
- Entering a phase for the first time triggers lazy enrichment (Haiku +
  `web_search`), writes `Resource` rows to the tasks.

## Weekly Review (v1 scope)

- User opens `WeeklyReviewView`, taps "Revise my plan".
- `AgentClient.runRevise()` sends the past-7-days completion summary.
- Worker's Haiku classifier decides `none` / `small` / `deep`.
- `small` → Haiku applies patches inline.
- `deep` → escalates to Sonnet for structural revisions.
- Client applies `RoadmapPatch`es to SwiftData models.

## Persistence strategy

- `VersionedSchema` from v1 so migrations are mechanical later.
- All properties are optional or defaulted; every relationship has an
  inverse — CloudKit-safe if sync is flipped on in the future without a
  migration.
- Session state lives in a Durable Object today. The `SessionStore` protocol
  means a Neon Postgres implementation drops in at v1.1 without any client
  changes.
