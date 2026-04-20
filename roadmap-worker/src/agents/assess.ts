import type { Env } from "../index";
import { jsonStream } from "./_stream";

/// Assessment loop (Haiku 4.5). Each call is one turn: model sees the full
/// transcript (with cache_control on prior turns) and either asks the next
/// question or signals "done" by returning an empty question and a parsed
/// profile summary.
export async function handleAssess(request: Request, env: Env): Promise<Response> {
  const body = (await request.json()) as { sessionID: string; answer: string };

  return jsonStream(async (emit) => {
    emit({ type: "stage_started", stage: "assess" });

    const session = env.SESSION.get(env.SESSION.idFromString(body.sessionID));
    // TODO: append answer to transcript, call Haiku with
    //   system: ASSESS_SYSTEM, cache_control: ephemeral
    //   messages: [...transcript]
    //   tools: [finalize_assessment]
    // When model fires finalize_assessment, emit stage_finished.

    await session.fetch("https://do/put", {
      method: "POST",
      body: JSON.stringify({ key: "lastAnswer", value: body.answer }),
    });

    emit({ type: "assistant_text", text: "What's your current level on a 1–5 scale?" });
    emit({ type: "stage_finished", stage: "assess", payload: JSON.stringify({ done: false }) });
  });
}
