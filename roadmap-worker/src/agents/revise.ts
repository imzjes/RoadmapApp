import type { Env } from "../index";
import { jsonStream } from "./_stream";

/// Weekly-review revision (Sonnet 4.6 for synthesis; Haiku for small tweaks).
/// Reads the user's past week of completion data plus their review notes,
/// produces patched phases and re-scheduled tasks.
export async function handleRevise(request: Request, env: Env): Promise<Response> {
  const body = (await request.json()) as { sessionID: string; review: string };

  return jsonStream(async (emit) => {
    emit({ type: "stage_started", stage: "revise" });

    const session = env.SESSION.get(env.SESSION.idFromString(body.sessionID));
    await session.fetch("https://do/put", {
      method: "POST",
      body: JSON.stringify({ key: "lastReview", value: body.review }),
    });

    // TODO: classify (small vs. deep), pick Haiku or Sonnet, stream revised
    // phases back as partial_json, finalize with stage_finished.
    emit({ type: "stage_finished", stage: "revise", payload: JSON.stringify({ patches: [] }) });
  });
}
