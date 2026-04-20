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

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const { pathname } = url;

    if (request.method === "POST" && pathname === "/v1/session") {
      return createSession(env);
    }

    const sessionMatch = pathname.match(/^\/v1\/session\/([^/]+)$/);
    if (request.method === "DELETE" && sessionMatch) {
      return endSession(env, sessionMatch[1]);
    }

    if (request.method !== "POST") {
      return new Response("method not allowed", { status: 405 });
    }

    switch (pathname) {
      case "/v1/intake": return handleIntake(request, env);
      case "/v1/assess": return handleAssess(request, env);
      case "/v1/generate": return handleGenerate(request, env);
      case "/v1/enrich": return handleEnrich(request, env);
      case "/v1/revise": return handleRevise(request, env);
      default: return new Response("not found", { status: 404 });
    }
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
