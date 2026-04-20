# Data model

SwiftData schema v1. All models live in `Models/Schema/RoadmapSchemaV1.swift`.

## Entities

### `Roadmap`

The top-level user plan.

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | `@Attribute(.unique)` |
| `goal` | String | Raw user input. |
| `title` / `summary` / `level` | String? | Filled by the generator. |
| `statusRaw` | String | `RoadmapStatus` (draft/active/completed/archived). |
| `assessmentJSON` | String? | Assessment profile, for revise stage. |
| `createdAt` / `updatedAt` | Date | — |
| `phases` | [Phase]? | Cascade delete; inverse `Phase.roadmap`. |
| `traces` | [AgentTrace]? | Cascade delete; inverse `AgentTrace.roadmap`. |

### `Phase`

An ordered chunk of a roadmap.

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | |
| `title` / `summary` | String / String? | |
| `orderIndex` | Int | SwiftData relationships are sets; ordering is client-side. |
| `targetWeeks` | Int | Used by `ScheduleEngine`. |
| `startDate` / `endDate` | Date? | Filled when schedule is assigned. |
| `roadmap` | Roadmap? | Inverse. |
| `tasks` | [LearningTask]? | Cascade delete; inverse `LearningTask.phase`. |

### `LearningTask`

Individual practice/study unit. Name is `LearningTask` to avoid colliding
with Swift concurrency's `Task`.

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | |
| `title` / `detail` | String / String? | |
| `orderIndex` | Int | Ordered within the phase. |
| `durationMinutes` | Int | |
| `scheduledDate` | Date? | Populated by `ScheduleEngine`. |
| `completedAt` | Date? | `nil` → not done. |
| `phase` | Phase? | Inverse. |
| `resources` | [Resource]? | Cascade delete; inverse `Resource.task`. |

### `Resource`

A free learning resource attached to a task.

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | |
| `title` / `urlString` | String | |
| `kindRaw` | String | `ResourceKind` enum. |
| `author` / `durationMinutes` / `summary` | optional | |
| `task` | LearningTask? | Inverse. |

### `AgentTrace`

Audit record for every agent call the app makes. Drives the course demo's
AgentTrace screen.

| Field | Type | Notes |
|-------|------|-------|
| `id` | UUID | |
| `stageRaw` | String | `AgentStage` enum. |
| `model` | String | E.g. `claude-haiku-4-5-20251001`. |
| `requestSummary` / `responseSummary` | String? | Short human-readable digest. |
| `inputTokens` / `cachedInputTokens` / `outputTokens` | Int | Token accounting. |
| `durationMs` | Int | Wall time. |
| `createdAt` | Date | |
| `roadmap` | Roadmap? | Inverse. |

## Ordering

To-many SwiftData relationships are **unordered sets**. `RoadmapSchemaLatest.swift`
provides `orderedPhases`, `orderedTasks`, `orderedResources` helpers that
sort by `orderIndex` (or title, for resources). Always use them — never iterate
the raw relationship array when order matters.

## Enums

- `RoadmapStatus`: draft · active · completed · archived.
- `ResourceKind`: youtube · article · doc · podcast · course · video.
- `AgentStage`: intake · assess · generate · enrich · resources · revise.

Stored as raw strings on each model; typed accessors live as computed
properties in `RoadmapSchemaLatest.swift`.

## Migration

`RoadmapMigrationPlan` is registered but has an empty `stages` array at v1.
When a schema change is needed:

1. Copy `RoadmapSchemaV1` to `RoadmapSchemaV2`.
2. Modify the V2 types.
3. Add a `MigrationStage` (lightweight or custom) to `RoadmapMigrationPlan.stages`.
4. Update `SchemaLatest` typealiases to point at V2.
