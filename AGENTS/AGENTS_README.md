# AGENTS_README.md

Shared instructions for agent entry files.

Read this file automatically and follow these rules before running session bootstrap.

- Run bootstrap only once at session start.
- Do not re-run bootstrap on every interaction.
- Re-run bootstrap only when the user explicitly asks to reload agent context.
- Security rule (mandatory): never insert secrets in workflow JSON files (API keys, tokens, passwords, private keys, auth headers, cookies, personal data).

## Common File Map
- `AGENTS.md`: Codex/ChatGPT entry point.
- `CLAUDE.md`: Claude Code entry point.
- `AGENTS/PROJECT.md`: project description, product scope, and workflows.
- `AGENTS/AI_BEHAVIOR.md`: AI agent behavior, workflow rules and issue management.
- `AGENTS/GIT_WORKFLOW.md`: branch, commit, PR, and sensitive-data commit gate rules.
- `AGENTS/IMPLEMENTATION_TRACK.md`: implementation roadmap and step-by-step feature track.
- `README.md`: human-readable quick project summary.
