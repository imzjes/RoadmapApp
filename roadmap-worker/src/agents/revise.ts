import type { Env } from "../index";
import { jsonStream } from "./_stream";
import { sessionStub } from "./_session";
import {
  anthropic,
  cachedSystem,
  firstTextBlock,
  MODEL_HAIKU,
  MODEL_SONNET,
  traceFromResponse,
} from "./_anthropic";
import { REVISE_CLASSIFY_SYSTEM, REVISE_PATCH_SYSTEM } from "../prompts";

/// Weekly-review revision. Two-step:
///   1. Haiku classifies the review as `none` / `small` / `deep`.
///   2. If `small` → Haiku emits patches. If `deep` → Sonnet rewrites the
///      affected phases. If `none` → return empty patches.
export async function handleRevise(request: Request, env: Env): Promise<Response> {
  const body = (await request.json()) as { sessionID: string; review: string };

  return jsonStream(async (emit) => {
    emit({ type: "stage_started", stage: "revise" });

    const session = sessionStub(env.SESSION.get(env.SESSION.idFromString(body.sessionID)));
    await session.put("lastReview", body.review);

    const roadmap = (await session.get<unknown>("roadmap")) ?? {};

    const client = anthropic(env.ANTHROPIC_API_KEY);

    // ── Step 1: Classify ─────────────────────────────────────────────────────
    const classifyStart = Date.now();
    const classifyResponse = await client.messages.create({
      model: MODEL_HAIKU,
      max_tokens: 16,
      system: cachedSystem(REVISE_CLASSIFY_SYSTEM),
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: `Weekly review notes:\n${body.review}\n\nClassify:` },
          ],
        },
      ],
    });
    const classification = firstTextBlock(classifyResponse.content).toLowerCase().trim();

    emit({
      type: "trace",
      trace: traceFromResponse({
        stage: "revise",
        model: MODEL_HAIKU,
        startedAt: classifyStart,
        requestSummary: "Triage weekly review",
        responseSummary: `Classification: ${classification}`,
        usage: classifyResponse.usage,
      }),
    });

    if (classification.startsWith("none")) {
      emit({
        type: "stage_finished",
        stage: "revise",
        payload: JSON.stringify({ classification: "none", patches: [] }),
      });
      return;
    }

    // ── Step 2: Patch ─────────────────────────────────────────────────────────
    const useSonnet = classification.startsWith("deep");
    const model = useSonnet ? MODEL_SONNET : MODEL_HAIKU;
    const patchStart = Date.now();

    const patchResponse = await client.messages.create({
      model,
      max_tokens: 4000,
      system: cachedSystem(REVISE_PATCH_SYSTEM),
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text:
                `Current roadmap:\n${JSON.stringify(roadmap, null, 2)}\n\n` +
                `User's weekly review:\n${body.review}\n\n` +
                `Classification from triage: ${classification}.\n` +
                `Return only the patches JSON.`,
            },
          ],
        },
      ],
    });

    const text = firstTextBlock(patchResponse.content).trim();
    const cleaned = stripJsonFence(text);
    let patches: unknown;
    try {
      patches = JSON.parse(cleaned);
    } catch {
      patches = { patches: [] };
    }

    emit({
      type: "trace",
      trace: traceFromResponse({
        stage: "revise",
        model,
        startedAt: patchStart,
        requestSummary: `Patch — ${classification}`,
        responseSummary: `${(patches as { patches?: unknown[] }).patches?.length ?? 0} patches`,
        usage: patchResponse.usage,
      }),
    });

    emit({
      type: "stage_finished",
      stage: "revise",
      payload: JSON.stringify({ classification, ...(patches as object) }),
    });
  });
}

function stripJsonFence(text: string): string {
  const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fenced) return fenced[1].trim();
  return text;
}
