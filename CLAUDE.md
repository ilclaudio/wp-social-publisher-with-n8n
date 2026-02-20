# CLAUDE.md

Claude Code specific entry point.
Project: `WP Social Publisher Approval Flow`.

Read `AGENTS/AGENTS_README.md` for shared agent rules and file map.

Mandatory security reminder: never insert secrets in workflow JSON files.
Synchronization rule: if you add instructions here, mirror them in `AGENTS.md`.

## Environment check preference
When validating `WSPAF_*` environment variables or testing n8n API connectivity, try PowerShell first (same context where variables are often set), then fall back to bash/WSL checks if needed.


## Session bootstrap
Run this section only once at session start, unless the user explicitly asks to reload CLAUDE context.

1. Read `AGENTS/PROJECT.md`.
2. Read `AGENTS/GIT_WORKFLOW.md`.
3. Read `AGENTS/IMPLEMENTATION_TRACK.md`.
4. Read `README.md`.
5. Report exactly: `Bootstrap completed` + the full list of files read (include `CLAUDE.md`, `AGENTS/PROJECT.md`, `AGENTS/GIT_WORKFLOW.md`, `AGENTS/IMPLEMENTATION_TRACK.md`, `README.md`).
