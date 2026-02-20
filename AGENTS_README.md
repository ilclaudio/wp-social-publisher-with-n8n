# AGENTS_README.md

Shared instructions for agent entry files.

Read this file automatically and follow these rules before running session bootstrap.

- Run bootstrap only once at session start.
- Do not re-run bootstrap on every interaction.
- Re-run bootstrap only when the user explicitly asks to reload agent context.

## Common File Map
- `AGENTS.md`: Codex/ChatGPT entry point.
- `CLAUDE.md`: Claude Code entry point.
- `PROJECT.md`: project description, product scope, and workflows.
- `GIT_WORKFLOW.md`: branch, commit, PR, and sensitive-data commit gate rules.
- `README.md`: human-readable quick project summary.
