import type { Env } from "../index";
import { jsonStream } from "./_stream";
import { sessionStub, type AssessmentTurn } from "./_session";
import {
  anthropic,
  cachedSystem,
  firstToolUse,
  MODEL_HAIKU,
  traceFromResponse,
  CACHE_EPHEMERAL,
} from "./_anthropic";
import { ASSESS_SYSTEM } from "../prompts";
import type Anthropic from "@anthropic-ai/sdk";

/// One turn of the adaptive assessment loop. Appends the user's answer to
/// the transcript, calls Haiku, and either:
///   - emits the next question (`ask_question` tool), or
///   - emits the finalized profile (`finalize_assessment` tool).
export async function handleAssess(request: Request, env: Env): Promise<Response> {
  const body = (await request.json()) as { sessionID: string; answer: string };

  return jsonStream(async (emit) => {
    emit({ type: "stage_started", stage: "assess" });

    const session = sessionStub(env.SESSION.get(env.SESSION.idFromString(body.sessionID)));
    const goal = (await session.get<string>("goal")) ?? "";
    const transcript = (await session.get<AssessmentTurn[]>("transcript")) ?? [];

    // The intake stage seeds the first question; subsequent calls answer the
    // most recent unanswered question, then continue.
    const last = transcript[transcript.length - 1];
    if (last && !last.answer) {
      last.answer = body.answer;
    } else {
      transcript.push({ answer: body.answer });
    }
    await session.put("transcript", transcript);

    const messages = buildAssessMessages(goal, transcript);
    const client = anthropic(env.ANTHROPIC_API_KEY);
    const startedAt = Date.now();

    const response = await client.messages.create({
      model: MODEL_HAIKU,
      max_tokens: 600,
      system: cachedSystem(ASSESS_SYSTEM),
      tools: [ASK_QUESTION_TOOL, FINALIZE_TOOL],
      messages,
    });

    const finalize = firstToolUse(response.content, "finalize_assessment");
    if (finalize) {
      const profile = (finalize.input as Record<string, unknown>) ?? {};
      await session.put("assessment", profile);

      emit({
        type: "trace",
        trace: traceFromResponse({
          stage: "assess",
          model: MODEL_HAIKU,
          startedAt,
          requestSummary: `Turn ${transcript.length} · finalize`,
          responseSummary: "Profile finalized",
          usage: response.usage,
        }),
      });
      emit({
        type: "stage_finished",
        stage: "assess",
        payload: JSON.stringify({ done: true, profile }),
      });
      return;
    }

    const ask = firstToolUse(response.content, "ask_question");
    const input = (ask?.input as { text?: string; kind?: string; suggestions?: string[] }) ?? {};
    const text = (input.text ?? "What's your current level?").toString();
    const kind = (["closed-chips", "chips-plus-other", "open"] as const).find(
      (k) => k === input.kind,
    ) ?? "open";
    const suggestions = Array.isArray(input.suggestions) ? input.suggestions.map(String) : [];

    transcript.push({ question: text });
    await session.put("transcript", transcript);

    emit({
      type: "assistant_text",
      text,
      meta: { kind, suggestions: suggestions.length ? suggestions : undefined },
    });
    emit({
      type: "trace",
      trace: traceFromResponse({
        stage: "assess",
        model: MODEL_HAIKU,
        startedAt,
        requestSummary: `Turn ${transcript.length} · ask`,
        responseSummary: text,
        usage: response.usage,
      }),
    });
    emit({
      type: "stage_finished",
      stage: "assess",
      payload: JSON.stringify({ done: false, question: text, kind, suggestions }),
    });
  });
}

// MARK: Tool defs

const ASK_QUESTION_TOOL: Anthropic.Messages.Tool = {
  name: "ask_question",
  description: "Ask the user the next assessment question.",
  input_schema: {
    type: "object",
    properties: {
      text: { type: "string", description: "The question to show the user." },
      kind: {
        type: "string",
        enum: ["closed-chips", "chips-plus-other", "open"],
        description:
          "How the client should render the input. closed-chips: 3–5 mutually exclusive chip options, no text input. chips-plus-other: chips plus an 'Other…' chip that reveals a text field. open: free-form text input only.",
      },
      suggestions: {
        type: "array",
        items: { type: "string" },
        description: "3–5 short answer chips (required for closed-chips and chips-plus-other).",
      },
    },
    required: ["text", "kind"],
  },
};

const FINALIZE_TOOL: Anthropic.Messages.Tool = {
  name: "finalize_assessment",
  description: "End the assessment. Pass a concise profile that the roadmap-generation stage will consume.",
  input_schema: {
    type: "object",
    properties: {
      level: { type: "string", description: "Current skill level in plain language." },
      weeklyHours: { type: "number", description: "Approximate hours per week the user can practice." },
      cadence: { type: "string", description: "Days per week, or a description like 'weekday mornings'." },
      style: { type: "string", description: "Preferred learning style." },
      outcome: { type: "string", description: "Specific, measurable target outcome." },
      constraints: { type: "string", description: "Budget, equipment, deadlines, etc." },
      notes: { type: "string", description: "Anything else worth knowing." },
    },
    required: [],
  },
};

// MARK: Message builder

function buildAssessMessages(
  goal: string,
  transcript: AssessmentTurn[],
): Anthropic.Messages.MessageParam[] {
  const messages: Anthropic.Messages.MessageParam[] = [];

  // Anchor with the goal as the opening user turn. Cache breakpoint #1 sits
  // here — it's the stable prefix every assess call reuses.
  // (Breakpoint #2 lives on the system prompt via cachedSystem.)
  messages.push({
    role: "user",
    content: [
      {
        type: "text",
        text: `The user's stated goal: "${goal}".`,
        cache_control: CACHE_EPHEMERAL,
      },
    ],
  });

  // Replay the transcript without further cache_control blocks — Anthropic
  // caps the request at 4 breakpoints total and we want headroom.
  for (const turn of transcript) {
    if (turn.question) {
      messages.push({
        role: "assistant",
        content: [{ type: "text", text: turn.question }],
      });
    }
    if (turn.answer) {
      messages.push({
        role: "user",
        content: [{ type: "text", text: turn.answer }],
      });
    }
  }

  return messages;
}
