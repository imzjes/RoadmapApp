import { handleAssess } from "./agents/assess";
import { handleEnrich } from "./agents/enrich";
import { handleGenerate } from "./agents/generate";
import { handleIntake } from "./agents/intake";
import { handleRevise } from "./agents/revise";
export { SessionDO } from "./session/SessionDO";

export interface Env {
  ANTHROPIC_API_KEY: string;
  RESOURCE_CACHE: KVNamespace;
  SESSION: DurableObjectNamespace;
  LANGFUSE_PUBLIC_KEY?: string;
  LANGFUSE_SECRET_KEY?: string;
}

const CORS_HEADERS: Record<string, string> = {
  "access-control-allow-origin": "*",
  "access-control-allow-methods": "GET, POST, DELETE, OPTIONS",
  "access-control-allow-headers": "content-type, accept",
  "access-control-max-age": "86400",
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const { pathname } = url;

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    let response: Response;
    if (request.method === "POST" && pathname === "/v1/session") {
      response = await createSession(env);
    } else {
      const sessionMatch = pathname.match(/^\/v1\/session\/([^/]+)$/);
      if (request.method === "DELETE" && sessionMatch) {
        response = await endSession(env, sessionMatch[1]);
      } else if (request.method === "GET" && pathname === "/health") {
        response = Response.json({ ok: true });
      } else if (request.method !== "POST") {
        response = new Response("method not allowed", { status: 405 });
      } else {
        switch (pathname) {
          case "/v1/intake": response = await handleIntake(request, env); break;
          case "/v1/assess": response = await handleAssess(request, env); break;
          case "/v1/generate": response = await handleGenerate(request, env); break;
          case "/v1/enrich": response = await handleEnrich(request, env); break;
          case "/v1/revise": response = await handleRevise(request, env); break;
          default: response = new Response("not found", { status: 404 });
        }
      }
    }

    // Layer CORS onto every response. Streamed bodies (text/event-stream) keep
    // their original headers; we just add the CORS allow- headers.
    const merged = new Headers(response.headers);
    for (const [key, value] of Object.entries(CORS_HEADERS)) {
      merged.set(key, value);
    }
    return new Response(response.body, {
      status: response.status,
      headers: merged,
    });
  },
};

async function createSession(env: Env): Promise<Response> {
  const id = env.SESSION.newUniqueId();
  const stub = env.SESSION.get(id);
  await stub.fetch("https://do/init", { method: "POST" });
  return Response.json({ id: id.toString() });
}

async function endSession(env: Env, id: string): Promise<Response> {
  const doID = env.SESSION.idFromString(id);
  const stub = env.SESSION.get(doID);
  await stub.fetch("https://do/end", { method: "DELETE" });
  return new Response(null, { status: 204 });
}
