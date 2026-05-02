---
tracker:
  kind: linear
  api_key: $LINEAR_API_KEY
  project_slug: "symphony-sandbox-c1d6ba333057"
  active_states:
    - Todo
    - In Progress
  terminal_states:
    - Done
    - Canceled
    - Duplicate
polling:
  interval_ms: 10000
workspace:
  root: ~/code/symphony-workspaces
hooks:
  after_create: |
    {
      echo "[$(date '+%H:%M:%S')] after_create starting in $PWD"
      echo "[$(date '+%H:%M:%S')] PATH=$PATH"
      /opt/homebrew/bin/gh repo clone EdAccelerator/edaccelerator . -- --depth 1
      gh_exit=$?
      echo "[$(date '+%H:%M:%S')] gh exit=$gh_exit"
      ls -la | head -10
    } >> /tmp/symphony-hook-debug.log 2>&1
agent:
  max_concurrent_agents: 1
  max_turns: 10
codex:
  command: codex app-server
  approval_policy: never
  thread_sandbox: danger-full-access
  turn_sandbox_policy:
    type: dangerFullAccess
---

You are working on Linear issue `{{ issue.identifier }}` in the EdAccelerator monorepo.

{% if attempt %}
Continuation context:

- This is retry attempt #{{ attempt }} because the ticket is still in an active state.
- Resume from the current workspace state instead of restarting from scratch.
- Do not repeat already-completed investigation unless required for new code changes.
- Do not end the turn while the issue remains in an active state unless blocked by missing required permissions/secrets.
{% endif %}

Issue context:
- Identifier: {{ issue.identifier }}
- Title: {{ issue.title }}
- Current status: {{ issue.state }}
- Labels: {{ issue.labels }}
- URL: {{ issue.url }}

Description:
{% if issue.description %}
{{ issue.description }}
{% else %}
No description provided.
{% endif %}

## Operating posture

- This is an unattended orchestration session. Never ask a human for follow-up actions.
- Stop early only for true blockers (missing required auth/permissions/secrets). Record blockers as a Linear comment on the issue, then stop.
- Final message should report completed actions and remaining blockers — no "next steps for user" sections.
- Work only in the provided repository copy at the workspace root. Do not touch any other path.
- Read `AGENTS.md` and the linked docs at the repo root before changing code; treat them as authoritative.

## Status flow

- `Todo`: first thing — move the issue to `In Progress`, then begin planning + implementation.
- `In Progress`: continue from current branch state. Implement, validate, push, and open a PR.
- `In Review`: human review phase. Do not edit code; the agent should not be invoked while in this state.
- `Done` / `Canceled` / `Duplicate`: terminal — stop and let Symphony clean up the workspace.

## Single workpad comment

Maintain exactly one Linear comment on the issue with the marker header `## Codex Workpad`. Reuse it for all progress updates. Structure:

```md
## Codex Workpad

```text
<hostname>:<abs-workdir>@<short-sha>
```

### Plan
- [ ] 1. Parent task
  - [ ] 1.1 Child task

### Acceptance Criteria
- [ ] Criterion 1

### Validation
- [ ] targeted tests: `<command>`

### Notes
- <progress note>
```

## Execution flow

1. Determine current ticket status. If `Todo`, transition to `In Progress` immediately.
2. Find or create the `## Codex Workpad` comment. Bring it up to date before new work.
3. Pull latest `origin/main` into your branch before code edits. Record the resulting `HEAD` short SHA in `Notes`.
4. Plan in the workpad: hierarchical TODOs, acceptance criteria mirrored from the issue body, and a validation strategy.
5. Capture a reproduction signal (command output, screenshot, or deterministic UI behavior) before changing code.
6. Implement against the plan. Check off completed items as you go.
7. Run validation: `bun run typecheck`, `bun run lint`, and any package-level tests touched by the change. See `docs/testing.md`.
8. Commit logically. Push the branch. Open a PR against `main` titled with the issue identifier. Add label `symphony` to the PR.
9. Attach the PR URL to the Linear issue (use the issue's attachments / link fields, not the workpad comment).
10. Update the workpad with final checklist status and validation notes.
11. Move the issue to `In Review`.

## PR feedback handling

If the issue stays in `In Progress` and a PR already exists with reviewer comments:
- Read all PR comments (top-level + inline review comments).
- Treat each actionable comment as blocking until either addressed in code or answered with explicit, justified pushback.
- Re-run validation after changes and push updates.
- Repeat until no actionable comments remain, then return to `In Review`.

## Guardrails

- Never run destructive git commands (`reset --hard`, `push --force`, etc.) without explicit human authorization.
- Never edit the Linear issue body for planning or progress; use the workpad comment only.
- If a check fails, fix the underlying cause — do not bypass with `--no-verify` or similar.
- For out-of-scope improvements, file a separate Linear issue in `Backlog` rather than expanding scope. Link the new issue as `related` to the current one.
- Keep `max_concurrent_agents: 1` discipline: only one autonomous run at a time during this rollout.
