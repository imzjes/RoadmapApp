import type { Env } from "../index";
import { jsonStream } from "./_stream";
import {
  anthropic,
  cachedSystem,
  firstTextBlock,
  MODEL_HAIKU,
  traceFromResponse,
} from "./_anthropic";
import { ENRICH_SYSTEM } from "../prompts";

interface PhaseTaskDTO {
  title: string;
  detail?: string;
}

interface EnrichRequestBody {
  /// Stable identifier (any string) — used as the KV cache key. Pass the
  /// SwiftData phase UUID from the client.
  phaseID: string;
  phaseTitle: string;
  tasks: PhaseTaskDTO[];
}

/// Phase enrichment (Haiku 4.5 + Anthropic-hosted web_search). Stateless:
/// the client sends the phase + tasks in the request body, so the worker
/// doesn't need an active session DO. Resources are cached in KV by phaseID.
export async function handleEnrich(request: Request, env: Env): Promise<Response> {
  const body = (await request.json()) as EnrichRequestBody;

  return jsonStream(async (emit) => {
    emit({ type: "stage_started", stage: "enrich" });

    const cacheKey = `phase:${body.phaseID}`;
    const cached = await env.RESOURCE_CACHE.get(cacheKey);
    if (cached) {
      emit({
        type: "trace",
        trace: {
          stage: "enrich",
          model: "kv-cache",
          requestSummary: `Phase "${body.phaseTitle}"`,
          responseSummary: "Cache hit — no model call",
          inputTokens: 0,
          outputTokens: 0,
          cachedInputTokens: 0,
          durationMs: 0,
        },
      });
      emit({ type: "stage_finished", stage: "enrich", payload: cached });
      return;
    }

    if (!body.tasks?.length) {
      emit({ type: "stage_finished", stage: "enrich", payload: JSON.stringify({ resources: [] }) });
      return;
    }

    const userTurn =
      `Phase: "${body.phaseTitle}"\n` +
      `Tasks:\n` +
      body.tasks
        .map((t, i) => `  ${i + 1}. ${t.title}${t.detail ? ` — ${t.detail}` : ""}`)
        .join("\n") +
      `\n\nUse web_search to find at most 2 free, high-quality resources per task. ` +
      `Return only the JSON described in the system prompt.`;

    const client = anthropic(env.ANTHROPIC_API_KEY);
    const startedAt = Date.now();

    emit({
      type: "tool_use",
      name: "web_search",
      input: { phase: body.phaseTitle },
    });

    const response = await client.messages.create({
      model: MODEL_HAIKU,
      max_tokens: 3000,
      system: cachedSystem(ENRICH_SYSTEM),
      tools: [{ type: "web_search_20250305", name: "web_search", max_uses: 8 } as any],
      messages: [{ role: "user", content: [{ type: "text", text: userTurn }] }],
    });

    const text = firstTextBlock(response.content).trim();
    const cleaned = stripJsonFence(text);
    let parsed: unknown;
    try {
      parsed = JSON.parse(cleaned);
    } catch {
      parsed = { resources: [] };
    }

    const payload = JSON.stringify(parsed);
    // Cache for 60 days — phase resources change rarely.
    await env.RESOURCE_CACHE.put(cacheKey, payload, { expirationTtl: 60 * 24 * 60 * 60 });

    emit({
      type: "tool_result",
      name: "web_search",
      summary: `Resolved resources for "${body.phaseTitle}"`,
    });

    emit({
      type: "trace",
      trace: traceFromResponse({
        stage: "enrich",
        model: MODEL_HAIKU,
        startedAt,
        requestSummary: `Phase "${body.phaseTitle}"`,
        responseSummary: `${(parsed as { resources?: unknown[] }).resources?.length ?? 0} resources`,
        usage: response.usage,
      }),
    });

    emit({ type: "stage_finished", stage: "enrich", payload });
  });
}

function stripJsonFence(text: string): string {
  const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fenced) return fenced[1].trim();
  return text;
}
