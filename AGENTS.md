# AGENTS.md

ChatGPT/Codex specific entry point.

Read `AGENTS/AGENTS_README.md` for shared agent rules and file map.

Mandatory security reminder: never insert secrets in workflow JSON files.
Synchronization rule: if you add instructions here, mirror them in `CLAUDE.md`.


## Session bootstrap
Run this section only once at session start, unless the user explicitly asks to reload AGENTS context.

1. Read `AGENTS/PROJECT.md`.
2. Read `AGENTS/GIT_WORKFLOW.md`.
3. Read `AGENTS/IMPLEMENTATION_TRACK.md`.
4. Read `README.md`.
5. Report exactly: `Bootstrap completed` + the full list of files read (include `AGENTS.md`, `AGENTS/PROJECT.md`, `AGENTS/GIT_WORKFLOW.md`, `AGENTS/IMPLEMENTATION_TRACK.md`, `README.md`).
