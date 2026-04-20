/// <reference types="@cloudflare/workers-types" />

/// Minimal newline-delimited JSON streamer shared by every agent stage.
/// The iOS client reads one event per line and decodes via `AgentEvent.decode`.
export type AgentEvent =
  | { type: "stage_started"; stage: string }
  | { type: "assistant_text"; text: string }
  | { type: "tool_use"; name: string; input: Record<string, string> }
  | { type: "tool_result"; name: string; summary: string }
  | { type: "partial_json"; json: string }
  | { type: "trace"; trace: AgentTrace }
  | { type: "stage_finished"; stage: string; payload: string }
  | { type: "error"; message: string };

export interface AgentTrace {
  stage: string;
  model: string;
  requestSummary?: string;
  responseSummary?: string;
  inputTokens: number;
  outputTokens: number;
  cachedInputTokens: number;
  durationMs: number;
}

export function jsonStream(
  handler: (emit: (event: AgentEvent) => void) => Promise<void>,
): Response {
  const { readable, writable } = new TransformStream<Uint8Array, Uint8Array>();
  const writer = writable.getWriter();
  const encoder = new TextEncoder();

  const emit = (event: AgentEvent) => {
    writer.write(encoder.encode(JSON.stringify(event) + "\n"));
  };

  (async () => {
    try {
      await handler(emit);
    } catch (err) {
      emit({ type: "error", message: (err as Error).message });
    } finally {
      await writer.close();
    }
  })();

  return new Response(readable, {
    headers: {
      "content-type": "text/event-stream",
      "cache-control": "no-cache",
      "transfer-encoding": "chunked",
    },
  });
}
