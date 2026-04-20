import type { Env } from "../index";
import { jsonStream } from "./_stream";

/// Phase enrichment (Haiku 4.5 + web_search). Runs lazily when the user
/// enters a phase, looks up free learning resources for every task, caches
/// results in KV by `task.title` hash so future users hit the cache.
export async function handleEnrich(request: Request, env: Env): Promise<Response> {
  const body = (await request.json()) as { sessionID: string; phaseID: string };

  return jsonStream(async (emit) => {
    emit({ type: "stage_started", stage: "enrich" });

    const cached = await env.RESOURCE_CACHE.get(`phase:${body.phaseID}`);
    if (cached) {
      emit({ type: "stage_finished", stage: "enrich", payload: cached });
      return;
    }

    // TODO: call Haiku with `web_search` tool enabled, loop tool_use ↔
    // tool_result, parse resources, persist to KV with a long TTL.
    emit({ type: "tool_use", name: "web_search", input: { q: "learn…" } });
    emit({ type: "tool_result", name: "web_search", summary: "…" });
    emit({ type: "stage_finished", stage: "enrich", payload: JSON.stringify({ resources: [] }) });
  });
}
