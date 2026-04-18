# AGENTS_README.md

Shared instructions for AI entry files.

Read this file before running session bootstrap.

## Bootstrap Rules

- Run bootstrap only once at session start.
- Do not re-run bootstrap on every interaction.
- Re-run bootstrap only when the user explicitly asks to reload agent context.
- Never insert secrets in workflow JSON files or repository-tracked documentation.

## File Roles

- `AGENTS.md`: Codex/ChatGPT entry point. Keep it short and tool-specific.
- `CLAUDE.md`: Claude Code entry point. Keep it short and tool-specific.
- `AGENTS/AI_BEHAVIOR.md`: reusable operating rules for AI assistants in n8n-oriented projects.
- `AGENTS/GIT_WORKFLOW.md`: reusable branch, commit, PR, and sensitive-data rules.
- `AGENTS/PROJECT.md`: project-specific context, conventions, variables, deploy rules, and workflow paths.
- `AGENTS/IMPLEMENTATION_TRACK.md`: roadmap, delivery status, open steps, and sequencing.
- `README.md`: human-readable summary of the current project state.

## Content Placement Rules

- Put reusable AI behavior in `AGENTS/AI_BEHAVIOR.md`.
- Put reusable Git process rules in `AGENTS/GIT_WORKFLOW.md`.
- Put project-specific values, workflow names, environment variables, trigger phrases, and deployment paths in `AGENTS/PROJECT.md`.
- Put execution progress and backlog status in `AGENTS/IMPLEMENTATION_TRACK.md`.
- Keep `AGENTS.md` and `CLAUDE.md` aligned, but avoid duplicating full shared rules there when a short pointer is enough.

## Deploy Strategy

**Primary deploy path: REST API (`scripts/deploy.ps1`)**
**Fallback deploy path: MCP `update_workflow`**

Rationale:

- The local workflow JSON is already maintained in `workflows/active/`. The REST deploy is a direct `PUT` of that file with credential ID injection — no intermediate format conversion.
- MCP `update_workflow` requires rewriting the entire workflow in SDK TypeScript format at deploy time. The local JSON is not reused — it must be reconstructed manually, which is slower and error-prone.
- MCP `update_workflow` also requires the "Available in MCP" toggle enabled on the target workflow in the n8n UI, adding a manual prerequisite.
- MCP credential auto-assignment is partial and inconsistent; the REST deploy script handles credential ID resolution explicitly via `GET /api/v1/credentials`.

MCP remains the **primary path for development tasks**: node discovery (`search_nodes`, `get_node_types`), pre-deploy validation (`validate_workflow`), workflow inspection (`get_workflow_details`), and execution analysis (`get_execution`). Use MCP `update_workflow` only when the REST API is unavailable or the API key is invalid.
