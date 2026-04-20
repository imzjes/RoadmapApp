# roadmap-worker

Cloudflare Worker that runs the roadmap-generation agent loop for the iOS app.

## Setup

1. `npm install`
2. Copy `.dev.vars.example` to `.dev.vars`, add your Anthropic key.
3. Create the KV namespace and paste the ID into `wrangler.toml`:
   ```sh
   npx wrangler kv namespace create RESOURCE_CACHE
   ```
4. `npm run dev` to run locally, `npm run deploy` to ship.

## Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/v1/session` | Create a session (Durable Object). |
| `DELETE` | `/v1/session/:id` | End a session. |
| `POST` | `/v1/intake` | Echo the user goal; emits the first assessment question. |
| `POST` | `/v1/assess` | One turn of the assessment loop. |
| `POST` | `/v1/generate` | Generate the full roadmap (Sonnet). |
| `POST` | `/v1/enrich` | Flesh out a phase lazily (Haiku). |
| `POST` | `/v1/revise` | Weekly-review-driven revision. |

All `POST` endpoints stream line-delimited JSON events (`{ type, ... }`) as the
agent loop runs. The iOS client decodes these into typed `AgentEvent`s.

## Agent loop

Each stage follows the same shape:

1. Build a messages array with prompt caching (`cache_control` on the system
   prompt + prior turns).
2. Call `messages.create` with a stage-appropriate model:
   - **Haiku 4.5** — intake, assess, enrich, revise-small, resources (with
     `web_search` tool).
   - **Sonnet 4.6** — generate, revise-synthesis.
3. If the model issues a `tool_use`, dispatch locally, append a
   `tool_result`, and loop.
4. Emit structured `trace` events after every model call so the client can
   show the progress stream.

See `src/prompts/` for the system prompts and `src/agents/` for each stage.
