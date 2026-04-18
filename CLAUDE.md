# CLAUDE.md

Claude Code entry point for `WP Social Publisher Approval Flow`.

Read `AGENTS/AGENTS_README.md` first for shared file roles and bootstrap rules.

## Claude-specific Notes

- Keep `AGENTS.md` aligned when changing entrypoint-level instructions.
- Never insert secrets in workflow JSON files.
- Provide a concise completion summary with:
  1. what changed
  2. which files were touched
  3. the next suggested step

## Session Bootstrap

Run this section only once at session start, unless the user explicitly asks to reload CLAUDE context.

1. Read `AGENTS/PROJECT.md`.
2. Read `AGENTS/AI_BEHAVIOR.md`.
3. Read `AGENTS/GIT_WORKFLOW.md`.
4. Read `AGENTS/IMPLEMENTATION_TRACK.md`.
5. Read `README.md`.
6. Report exactly: `Bootstrap completed` + the full list of files read (include `CLAUDE.md`, `AGENTS/PROJECT.md`, `AGENTS/GIT_WORKFLOW.md`, `AGENTS/IMPLEMENTATION_TRACK.md`, `README.md`).
