# AGENTS.md

ChatGPT/Codex specific entry point.
Project: `WP Social Publisher Approval Flow`.

Read `AGENTS/AGENTS_README.md` for shared agent rules and file map.

Mandatory security reminder: never insert secrets in workflow JSON files.
Synchronization rule: if you add instructions here, mirror them in `CLAUDE.md`.

## Environment check preference
When validating `WSPAF_*` environment variables or testing n8n API connectivity, try PowerShell first (same context where variables are often set), then fall back to bash/WSL checks if needed.

## Active workflow replacement rule
When replacing an existing file in `workflows/active/` with a draft workflow:
1. Create a dated backup of the current active file first (for example `*.backup-YYYY-MM-DD.json`).
2. Copy the selected draft into `workflows/active/`.
3. Keep the canonical workflow name in the active JSON (unless the user explicitly requests a rename).


## n8n deploy confirmation rule
Before copying or deploying any workflow changes to the n8n server (API `POST`/`PUT`, activation/deactivation, or import-equivalent actions), ask the user for explicit confirmation and wait for approval before executing the server-side action.

## Completion summary rule
After completing changes or finishing a task, provide a concise summary of:
1. What was changed.
2. Which files were touched.
3. What remains as the next suggested step in context.

## Session bootstrap
Run this section only once at session start, unless the user explicitly asks to reload AGENTS context.

1. Read `AGENTS/PROJECT.md`.
2. Read `AGENTS/AI_BEHAVIOR.md`.
3. Read `AGENTS/GIT_WORKFLOW.md`.
4. Read `AGENTS/IMPLEMENTATION_TRACK.md`.
5. Read `README.md`.
6. Report exactly: `Bootstrap completed` + the full list of files read (include `AGENTS.md`, `AGENTS/PROJECT.md`, `AGENTS/GIT_WORKFLOW.md`, `AGENTS/IMPLEMENTATION_TRACK.md`, `README.md`).
