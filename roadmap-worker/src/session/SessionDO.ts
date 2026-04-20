/// <reference types="@cloudflare/workers-types" />

/// Durable Object holding per-session agent state:
///   - raw user goal
///   - assessment transcript (question/answer turns)
///   - generated roadmap draft
///   - token usage so far
///
/// v1.1 will add a `PostgresSessionStore` that implements the same methods
/// against a `sessions` table keyed by user_id, so the Swift client swap is a
/// config change.
export class SessionDO {
  state: DurableObjectState;

  constructor(state: DurableObjectState) {
    this.state = state;
  }

  async fetch(req: Request): Promise<Response> {
    const url = new URL(req.url);
    switch (url.pathname) {
      case "/init":
        await this.put("createdAt", Date.now());
        return new Response(null, { status: 204 });
      case "/end":
        await this.state.storage.deleteAll();
        return new Response(null, { status: 204 });
      case "/get": {
        const key = url.searchParams.get("key") ?? "";
        const value = await this.state.storage.get(key);
        return Response.json({ value: value ?? null });
      }
      case "/put": {
        const body = (await req.json()) as { key: string; value: unknown };
        await this.state.storage.put(body.key, body.value);
        return new Response(null, { status: 204 });
      }
      default:
        return new Response("not found", { status: 404 });
    }
  }

  private async put(key: string, value: unknown): Promise<void> {
    await this.state.storage.put(key, value);
  }
}
