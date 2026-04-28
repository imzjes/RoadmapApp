import Anthropic from "@anthropic-ai/sdk";
import type { AgentTrace } from "./_stream";

export const MODEL_HAIKU = "claude-haiku-4-5-20251001";
export const MODEL_SONNET = "claude-sonnet-4-6";

/// Returns a configured Anthropic client. Prompt caching is applied at the
/// call site via `cache_control: { type: "ephemeral" }` blocks on the
/// system prompt and prior-turn messages — important for the course's cost
/// target ($0.11–$0.23 per user).
export function anthropic(apiKey: string): Anthropic {
  return new Anthropic({ apiKey });
}

/// Standard cache_control block. Apply to the system prompt and every
/// message that gets reused across turns in the session.
export const CACHE_EPHEMERAL = { type: "ephemeral" as const };

/// Build a cached system block from a plain string prompt.
export function cachedSystem(prompt: string) {
  return [{ type: "text" as const, text: prompt, cache_control: CACHE_EPHEMERAL }];
}

/// Convert a raw `messages.create` response into an AgentTrace row.
export function traceFromResponse(args: {
  stage: string;
  model: string;
  startedAt: number;
  requestSummary?: string;
  responseSummary?: string;
  usage: { input_tokens: number; output_tokens: number; cache_read_input_tokens?: number | null };
}): AgentTrace {
  return {
    stage: args.stage,
    model: args.model,
    requestSummary: args.requestSummary,
    responseSummary: args.responseSummary,
    inputTokens: args.usage.input_tokens,
    outputTokens: args.usage.output_tokens,
    cachedInputTokens: args.usage.cache_read_input_tokens ?? 0,
    durationMs: Date.now() - args.startedAt,
  };
}

/// Pull the first text block out of a model response. Used by stages that
/// expect plain prose output (intake, simple assess turns).
export function firstTextBlock(content: Anthropic.Messages.ContentBlock[]): string {
  for (const block of content) {
    if (block.type === "text") return block.text;
  }
  return "";
}

/// Pull the first tool_use block matching `name` out of a model response.
export function firstToolUse(
  content: Anthropic.Messages.ContentBlock[],
  name: string,
): Anthropic.Messages.ToolUseBlock | undefined {
  for (const block of content) {
    if (block.type === "tool_use" && block.name === name) {
      return block;
    }
  }
  return undefined;
}
