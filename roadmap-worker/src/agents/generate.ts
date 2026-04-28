import type { Env } from "../index";
import { jsonStream } from "./_stream";
import { sessionStub } from "./_session";
import {
  anthropic,
  cachedSystem,
  MODEL_SONNET,
  traceFromResponse,
} from "./_anthropic";
import { GENERATE_SYSTEM } from "../prompts";

/// Generation stage (Sonnet 4.6). Reads goal + assessment profile from the
/// session DO, asks Sonnet for the full roadmap as JSON, streams text deltas
/// as `partial_json` so the client can show progress, then emits the final
/// roadmap on `stage_finished`.
export async function handleGenerate(request: Request, env: Env): Promise<Response> {
  const body = (await request.json()) as { sessionID: string };

  return jsonStream(async (emit) => {
    emit({ type: "stage_started", stage: "generate" });

    const session = sessionStub(env.SESSION.get(env.SESSION.idFromString(body.sessionID)));
    const goal = (await session.get<string>("goal")) ?? "";
    const profile = (await session.get<Record<string, unknown>>("assessment")) ?? {};

    const userTurn =
      `Goal: ${goal}\n\n` +
      `Assessment profile:\n${JSON.stringify(profile, null, 2)}\n\n` +
      `Return only the roadmap JSON.`;

    const client = anthropic(env.ANTHROPIC_API_KEY);
    const startedAt = Date.now();

    const stream = client.messages.stream({
      model: MODEL_SONNET,
      max_tokens: 8000,
      system: cachedSystem(GENERATE_SYSTEM),
      messages: [{ role: "user", content: [{ type: "text", text: userTurn }] }],
    });

    let acc = "";
    for await (const event of stream) {
      if (event.type === "content_block_delta" && event.delta.type === "text_delta") {
        acc += event.delta.text;
        emit({ type: "partial_json", json: event.delta.text });
      }
    }

    const finalMessage = await stream.finalMessage();
    const cleaned = stripJsonFence(acc.trim());
    let roadmap: unknown;
    try {
      roadmap = JSON.parse(cleaned);
    } catch {
      // Fallback: try the model's parsed content (in case it returned JSON in a
      // way our delta concat fumbled).
      const text = finalMessage.content
        .filter((b) => b.type === "text")
        .map((b) => (b as { text: string }).text)
        .join("");
      roadmap = JSON.parse(stripJsonFence(text.trim()));
    }

    await session.put("roadmap", roadmap);

    emit({
      type: "trace",
      trace: traceFromResponse({
        stage: "generate",
        model: MODEL_SONNET,
        startedAt,
        requestSummary: `Goal "${goal}" + profile`,
        responseSummary: roadmapSummary(roadmap),
        usage: finalMessage.usage,
      }),
    });

    emit({
      type: "stage_finished",
      stage: "generate",
      payload: JSON.stringify(roadmap),
    });
  });
}

function stripJsonFence(text: string): string {
  // Sonnet sometimes wraps JSON in ```json …``` despite the instruction.
  const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fenced) return fenced[1].trim();
  return text;
}

function roadmapSummary(roadmap: unknown): string {
  const r = roadmap as { title?: string; phases?: unknown[] } | null;
  if (!r) return "Roadmap";
  const phaseCount = Array.isArray(r.phases) ? r.phases.length : 0;
  const taskCount = Array.isArray(r.phases)
    ? r.phases.reduce<number>((sum, phase) => {
        const p = phase as { tasks?: unknown[] };
        return sum + (Array.isArray(p.tasks) ? p.tasks.length : 0);
      }, 0)
    : 0;
  return `${r.title ?? "Roadmap"} · ${phaseCount} phases · ${taskCount} tasks`;
}
