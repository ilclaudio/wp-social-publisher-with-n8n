# AI_BEHAVIOR.md

## Purpose

Reusable operating rules for AI assistants collaborating on n8n-oriented codebases.

Project-specific variables, trigger phrases, workflow paths, and deployment targets belong in `AGENTS/PROJECT.md`.

## Execution Rules

- Be concise, precise, and action-oriented.
- Work one objective at a time, end-to-end.
- Ask clarifying questions only when ambiguity blocks implementation or creates material risk.
- After meaningful progress, summarize what changed and what remains.
- Propose the next best step after completing a task.
- Keep quality gates active: security, maintainability, and operational reliability.

## Safety Rules

- Never hardcode secrets, API keys, passwords, tokens, cookies, or personal data in workflow JSON or repository-tracked documentation.
- Before any remote deploy, activation, deactivation, or equivalent server-side change, ask for explicit user confirmation unless the project entry files define an approved trigger phrase.
- If the repository keeps active workflow files locally, follow the backup/replacement convention defined in `AGENTS/PROJECT.md` before overwriting them.

## n8n Interaction Strategy

- Prefer MCP for discovery, node lookup, validation, workflow inspection, and execution analysis when MCP is available.
- Use REST API (`scripts/deploy.ps1`) as the primary deploy path. MCP `update_workflow` is the fallback when the REST API is unavailable.
- Keep AI-session connectivity separate from workflow runtime configuration.

## Node Type Resolution

Before implementing a new n8n node, resolve the exact node type and parameter names for the target instance.

Primary method:
1. Use MCP `search_nodes` to find the correct node.
2. Note any returned discriminators such as `resource`, `operation`, `mode`, and `version`.
3. Use MCP `get_node_types` with those values.
4. Use only the parameter names returned by the tool.

Fallback when MCP is unavailable:
1. Scan existing workflows for the node type and `typeVersion` already in use.
2. If still unresolved, consult official n8n documentation.
3. If uncertainty remains, ask the user to confirm availability from the n8n UI before writing the node.

Always preserve the correct `typeVersion` for the target instance.

## Runtime and Configuration Discipline

- Distinguish between local development/tooling variables and workflow runtime variables.
- Keep runtime values in environment variables or n8n Variables as defined by the project.
- Keep secrets and authenticated integrations in n8n Credentials.
- Document project-specific variable names in `AGENTS/PROJECT.md`, not here.

## Workflow Code Standards

- Write code inside n8n `Code`, `Function`, or inline script nodes in JavaScript compatible with the n8n server runtime, unless the project explicitly documents another supported runtime.
- Prefer simple, working node configurations over speculative complexity.
- Reuse existing workflow patterns where possible to reduce drift.

## Repository Scope

Ignore generated or third-party directories unless the task explicitly requires them:
- `vendor/`
- `node_modules/`
