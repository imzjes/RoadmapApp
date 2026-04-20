# RoadmapApp

An iOS app that turns a one-sentence learning goal into a personalized,
calendarable roadmap. The planning pipeline is built as a visible multi-stage
agent loop — intake → adaptive assessment → generation → lazy enrichment →
weekly revision — so the user can see the agent's reasoning as it works.

Built as a final project for an Agentic AI course.

## How it works

1. **Intake.** User enters a goal in natural language ("play fingerstyle
   guitar", "basic Mandarin", "Rust for web").
2. **Assessment.** The app runs an adaptive questionnaire — one question at
   a time, choosing follow-ups based on prior answers — to learn the user's
   level, time budget, preferred cadence, and learning style.
3. **Generation.** A larger model synthesizes the full roadmap: a handful of
   phases, each broken into concrete tasks with realistic durations.
4. **Enrichment.** When the user enters a phase, a lighter model looks up
   free learning resources (YouTube, docs, articles) for each task and
   attaches them.
5. **Practice.** Tasks get scheduled on the user's cadence. Completing them
   updates a tasteful streak and feeds the weekly review.
6. **Weekly review.** Reads the past week's completion data, classifies the
   needed change (none / small / deep), and revises the plan accordingly.

## Architecture

**iOS app** — SwiftUI + SwiftData, pure Swift, no third-party dependencies.
MVVM with `@Observable` coordinators and singleton services. A
`VersionedSchema` SwiftData store keeps the data model future-proof for
CloudKit sync.

**Backend** — a Cloudflare Worker that hosts the agent pipeline. Each stage
is its own endpoint, calls the Anthropic API with prompt caching, and
streams structured events (newline-delimited JSON) back to the app. Session
state lives in a Durable Object; resource lookups are cached in KV across
users.

**Model split** — lighter model for intake, assessment, enrichment, and
small revisions; heavier model for full roadmap generation and structural
revisions. Combined with prompt caching, this targets ~$0.11–$0.23 per
user through onboarding + first month of use.

## Repository layout

```
RoadmapApp/            iOS app source
RoadmapApp.xcodeproj/  Xcode project (file-system synchronized groups)
RoadmapAppTests/       Swift Testing target
RoadmapAppUITests/     UI tests
Config/                xcconfig-based build configuration
roadmap-worker/        Cloudflare Worker (TypeScript)
docs/                  Architecture, data model, agent flow, patterns, gotchas
```

## Build

Requires Xcode 26+ and the iOS 26 SDK.

```sh
open RoadmapApp.xcodeproj
# set the RoadmapApp scheme, run on an iPhone 17 Pro simulator
```

The app runs with mock data if no worker URL is configured — the seed
roadmap under `Models/SeedData.swift` fills in during development.

## Backend

```sh
cd roadmap-worker
npm install
cp .dev.vars.example .dev.vars     # add your ANTHROPIC_API_KEY
npx wrangler kv namespace create RESOURCE_CACHE
# paste the returned ID into wrangler.toml
npx wrangler dev                    # local
npx wrangler deploy                 # ship
```

Copy the deployed URL into `Config/Secrets.xcconfig`:

```
SLASH = /
ROADMAP_WORKER_URL = https:$(SLASH)$(SLASH)your-worker.example.workers.dev
```

## Documentation

- `docs/architecture.md` — system overview and data flow diagrams.
- `docs/agent-flow.md` — each stage's model, tools, and event shape.
- `docs/data-model.md` — SwiftData schema and entity reference.
- `docs/patterns.md` — conventions for adding views, services, stages.
- `docs/gotchas.md` — platform-specific pitfalls worth knowing up front.

## Status

v1 scope: intake, assessment, generation, enrichment, weekly review,
in-app scheduling, per-task system-calendar add, notifications, streak
tracking, visible agent trace.

Deferred to v1.1: Neon Postgres sessions, Sign in with Apple, StoreKit 2,
bulk system-calendar scheduling, Langfuse observability wrapper.
