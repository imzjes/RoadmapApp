import Anthropic from "@anthropic-ai/sdk";

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
