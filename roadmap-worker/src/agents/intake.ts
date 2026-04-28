import type { Env } from "../index";
import { jsonStream } from "./_stream";
import { sessionStub } from "./_session";
import {
  anthropic,
  cachedSystem,
  firstTextBlock,
  MODEL_HAIKU,
  traceFromResponse,
} from "./_anthropic";
import { INTAKE_SYSTEM } from "../prompts";

/// Intake stage (Haiku 4.5). Takes the raw goal, restates it concretely, asks
/// the single most useful follow-up question. Persists the goal on the
/// session DO so later stages can read it without re-sending.
export async function handleIntake(request: Request, env: Env): Promise<Response> {
  const body = (await request.json()) as { goal: string; sessionID: string };

  return jsonStream(async (emit) => {
    emit({ type: "stage_started", stage: "intake" });

    const session = sessionStub(env.SESSION.get(env.SESSION.idFromString(body.sessionID)));
    await session.put("goal", body.goal);
    await session.put("transcript", []);

    const client = anthropic(env.ANTHROPIC_API_KEY);
    const startedAt = Date.now();

    const response = await client.messages.create({
      model: MODEL_HAIKU,
      max_tokens: 400,
      system: cachedSystem(INTAKE_SYSTEM),
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text:
                `The user wants to learn: "${body.goal}".\n\n` +
                `Restate the goal in one sentence so they know you heard them, ` +
                `then ask the single most useful follow-up question. ` +
                `Output two short paragraphs separated by a blank line — ` +
                `the restatement first, the question second. No greetings.`,
            },
          ],
        },
      ],
    });

    const text = firstTextBlock(response.content).trim();
    const [restate, ...rest] = text.split(/\n\s*\n/);
    const question = rest.join("\n\n").trim() || "What's your current level on a 1–5 scale?";

    emit({ type: "assistant_text", text: restate || `Got it — "${body.goal}".` });
    emit({
      type: "assistant_text",
      text: question,
      meta: { kind: "open" },
    });

    emit({
      type: "trace",
      trace: traceFromResponse({
        stage: "intake",
        model: MODEL_HAIKU,
        startedAt,
        requestSummary: `Goal: "${body.goal}"`,
        responseSummary: question,
        usage: response.usage,
      }),
    });

    // Seed the transcript with the assistant's first question so the assess
    // stage sees full conversation history on the next turn.
    await session.put("transcript", [{ question }]);

    emit({
      type: "stage_finished",
      stage: "intake",
      payload: JSON.stringify({ firstQuestion: question }),
    });
  });
}
