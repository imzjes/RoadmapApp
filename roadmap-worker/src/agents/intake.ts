import type { Env } from "../index";
import { jsonStream } from "./_stream";

/// Intake stage (Haiku 4.5): read the raw goal, emit the first assessment
/// question, persist the goal on the session DO.
export async function handleIntake(request: Request, env: Env): Promise<Response> {
  const body = (await request.json()) as { goal: string; sessionID: string };

  return jsonStream(async (emit) => {
    emit({ type: "stage_started", stage: "intake" });

    const session = env.SESSION.get(env.SESSION.idFromString(body.sessionID));
    await session.fetch("https://do/put", {
      method: "POST",
      body: JSON.stringify({ key: "goal", value: body.goal }),
    });

    // TODO: call Haiku with the intake system prompt.
    emit({ type: "assistant_text", text: `Great — you want to learn: ${body.goal}. Let's narrow it down.` });
    emit({
      type: "stage_finished",
      stage: "intake",
      payload: JSON.stringify({ firstQuestion: "How much time per week can you commit?" }),
    });
  });
}
