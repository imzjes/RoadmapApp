# Agent flow

The multi-stage agent pipeline is the visible center of the project. Each
stage is a separate Worker endpoint with its own system prompt and its own
`AgentTrace` row on the client.

## Stage table

| Stage | Endpoint | Model | Tools | Streaming shape |
|-------|----------|-------|-------|-----------------|
| intake | `POST /v1/intake` | Haiku 4.5 | — | text + `stage_finished` with first question |
| assess | `POST /v1/assess` | Haiku 4.5 | `finalize_assessment` | per-turn: question text, then `stage_finished` with `done: bool` |
| generate | `POST /v1/generate` | Sonnet 4.6 | — | `partial_json` as phases resolve, then final `stage_finished` with full roadmap |
| enrich | `POST /v1/enrich` | Haiku 4.5 | `web_search` | `tool_use` / `tool_result` pairs, final resource list |
| revise | `POST /v1/revise` | Haiku → Sonnet | — | classifier output, then patches |

## Session state

Each first `/v1/session` POST returns a session ID (Durable Object). The ID
is passed back on every subsequent call. The DO holds:

- the raw goal
- the assessment transcript
- the finalized assessment profile
- generated roadmap draft
- running token counters

The `SessionStore` interface on the Swift side is implementation-agnostic.
At v1.1 we swap in a Postgres-backed store with the same methods; no client
changes required.

## Prompt caching

Every stage:

1. Places its system prompt as a single `text` block with `cache_control: { type: "ephemeral" }`.
2. For loop stages (assess), marks the last persistent prior-turn pair with `cache_control` too.
3. Reports `cached_input_tokens` back to the client via the `trace` event.

Target cost: **$0.11–$0.23 per user** (full onboarding + first-month use).
Achieved by: Haiku on every loop turn, Sonnet only for generation/deep-revise,
lazy per-phase enrichment (pay once per user), KV cache on resources (pay
once across all users).

## Events emitted by the Worker

Every endpoint streams newline-delimited JSON objects. Shapes:

```
{ "type": "stage_started", "stage": "generate" }
{ "type": "assistant_text", "text": "Great — you want to learn…" }
{ "type": "tool_use", "name": "web_search", "input": { "q": "…" } }
{ "type": "tool_result", "name": "web_search", "summary": "Found 3…" }
{ "type": "partial_json", "json": "{\"title\":\"…" }
{ "type": "trace", "trace": { "stage": "…", "model": "…", "inputTokens": 1234, ... } }
{ "type": "stage_finished", "stage": "generate", "payload": "{...}" }
{ "type": "error", "message": "…" }
```

The Swift client decodes them into `AgentEvent` (see
`Services/AgentClient.swift`).

## Handling tool_use on the Worker

For stages that use tools (`assess` → `finalize_assessment`, `enrich` →
`web_search`, `resources` → `web_search`):

1. Call `messages.create` with `tools` defined.
2. If `stop_reason === "tool_use"`, run the tool locally.
3. Append `{ role: "user", content: [{ type: "tool_result", ... }] }`.
4. Loop until `stop_reason === "end_turn"`.

Emit `tool_use` / `tool_result` events as they happen — the iOS client
renders them in the AgentTrace screen.
