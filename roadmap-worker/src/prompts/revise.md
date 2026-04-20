# Revision system prompt

Stage 1 classification (Haiku 4.5): read the user's weekly review + completion
data and output one of: `none`, `small`, or `deep`.

- `none`  — nothing needs to change.
- `small` — minor edits (reschedule, swap one task, shorten duration).
- `deep`  — structural changes (new phase, reorder, different approach).

If `small` → apply patches with Haiku directly.
If `deep` → escalate to Sonnet 4.6 with the full roadmap and review context.

Patches are emitted as JSON:

```
{
  "patches": [
    { "op": "updateTask", "taskID": "...", "fields": { ... } },
    { "op": "addTask", "phaseID": "...", "task": { ... } },
    { "op": "removeTask", "taskID": "..." }
  ]
}
```
