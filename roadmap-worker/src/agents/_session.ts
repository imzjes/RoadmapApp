/// <reference types="@cloudflare/workers-types" />

/// Tiny wrapper around the SessionDO put/get endpoints so stage handlers
/// don't have to repeat the fetch boilerplate.
export function sessionStub(stub: DurableObjectStub) {
  return {
    async get<T = unknown>(key: string): Promise<T | null> {
      const res = await stub.fetch(`https://do/get?key=${encodeURIComponent(key)}`);
      const data = (await res.json()) as { value: T | null };
      return data.value;
    },
    async put(key: string, value: unknown): Promise<void> {
      await stub.fetch("https://do/put", {
        method: "POST",
        body: JSON.stringify({ key, value }),
      });
    },
  };
}

export interface AssessmentTurn {
  question?: string;
  answer?: string;
  done?: boolean;
}

export interface AssessmentProfile {
  level?: string;
  weeklyHours?: number;
  cadence?: string;
  style?: string;
  outcome?: string;
  constraints?: string;
  notes?: string;
}
