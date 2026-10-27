---
name: sync-docs
description: Bring this repo's markdown docs back in sync after a change. Use at the end of any task that changed modules, hosts, options, phases or conventions, when the user says "update the docs" / "sync docs" / "are the docs current", or before wrapping up a session that touched Nix files. Covers PLAN.md, TODO.md, docs/ARCHITECTURE.md, docs/OPTIONS.md, AGENTS.md and README.md.
---

# Sync the docs

Six files, each with one job. Keep every file self-contained enough that a fresh session can
orient without conversation history.

| File | Owns | After a change |
|---|---|---|
| PLAN.md | source of truth for what to do | tick finished checkboxes; never delete phases or decisions |
| TODO.md | only currently actionable items | drop what's done, add new next actions (e.g. validation on a Nix machine) |
| docs/ARCHITECTURE.md | how the config fits together | folder-scheme or data-flow changes → relevant sections; option-tree changes → point at OPTIONS.md |
| docs/OPTIONS.md | the complete `cfg.*` reference (types, defaults, per-host matrix) | options added/renamed/removed → update rows; host wiring flips → update the matrix |
| AGENTS.md | conventions & recipes for agents | update only when a convention itself changed (namespace, pins, new patterns) — same change, not later |
| README.md | project overview | host table + usage commands |

## Procedure

1. List what actually changed (git status/diff if unclear) — features, options, hosts, folders,
   conventions.
2. For each of the six files, check whether its "owns" column is affected; update only those.
3. Grep the changed feature/option name across all six files to catch stale mentions (e.g. an
   option listed in OPTIONS.md but renamed in the module).
4. Check the status lines: PLAN.md's header status and ARCHITECTURE.md's status note describe
   the current phase and validation state — update them if this change moved either.
5. Write for a fresh session: no references to "the conversation", no unexplained codenames.
   Someone reading PLAN.md → AGENTS.md → ARCHITECTURE.md should be able to continue without
   this session's history.
