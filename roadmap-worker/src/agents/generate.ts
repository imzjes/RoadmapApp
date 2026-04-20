import type { Env } from "../index";
import { jsonStream } from "./_stream";

/// Generation stage (Sonnet 4.6). Reads the assessment summary from the
/// session DO, produces the full roadmap as JSON, streams partial_json
/// events so the client can render phases as they resolve.
export async function handleGenerate(request: Request, env: Env): Promise<Response> {
  const body = (await request.json()) as { sessionID: string };

  return jsonStream(async (emit) => {
    emit({ type: "stage_started", stage: "generate" });

    const session = env.SESSION.get(env.SESSION.idFromString(body.sessionID));
    const assessmentRes = await session.fetch("https://do/get?key=assessment");
    const _assessment = await assessmentRes.json();

    // TODO:
    //   const client = anthropic(env.ANTHROPIC_API_KEY);
    //   const stream = await client.messages.stream({
    //     model: MODEL_SONNET,
    //     system: [{ type: "text", text: GENERATE_SYSTEM, cache_control: CACHE_EPHEMERAL }],
    //     messages: [...],
    //     max_tokens: 8000,
    //   });
    //   for await (const evt of stream) { emit(...) }

    emit({ type: "partial_json", json: '{"title":"…"}' });
    emit({ type: "stage_finished", stage: "generate", payload: JSON.stringify({ roadmap: {} }) });
  });
}
