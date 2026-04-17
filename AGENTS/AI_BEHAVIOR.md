# AI_BEHAVIOR.md

## Purpose
Operational rules for AI assistants working on this codebase.


## Execution Rules
- Be concise, precise, and action-oriented.
- Work one objective at a time, end-to-end.
- Ask clarifying questions only when ambiguity blocks implementation.
- After meaningful progress, summarize what changed and what remains.
- Be proactive: when a task is completed, always propose the next best step based on the current discussion context, `AGENTS/IMPLEMENTATION_TRACK.md`, and the project objective defined in `AGENTS/PROJECT.md`.
- Keep quality gates active: security, accessibility, maintainability.


## Learning Support
When useful, explain the theory behind choices (n8n internals, security, architecture, standards), especially if the user shows knowledge gaps or asks for deeper understanding.
Keep explanations practical and tied to the current code.


## Trigger Commands
Use the following trigger patterns and workflows.

### Deploy workflow to n8n server
Trigger phrases:
- `Aggiorna il flusso sul server`
- `Fai il deploy del flusso sul server`
- `Update the workflow on the server`
- `Deploy the workflow to the server`

Expected behavior:
- Treat the trigger phrase itself as explicit user confirmation for remote deploy.
- Before deploying, run `validate_workflow` via MCP to catch errors in the workflow code early.
- Use PowerShell first, not bash/WSL, to read `WSPAF_N8N_BASE_URL` and `WSPAF_N8N_API_KEY`.
- Deploy by running `scripts/deploy.ps1` (or equivalent PUT via REST API), not via MCP `update_workflow` — the script handles credential ID injection that MCP does not perform automatically.
- Default source file: `workflows/active/wp-social-publisher-approval-flow.json`, unless the user specifies a different workflow file.
- First identify the remote workflow by canonical name, then update that workflow in place.
- Exclude read-only fields from the request body.
- After deploy, verify with a follow-up `GET` that the remote workflow reflects the expected changes.
- Do not activate or deactivate the workflow unless the user explicitly requests it.
- At the end, report the workflow ID, whether it was updated in place, and the verification result.


## n8n Node Type Resolution

Before implementing any node not yet present in the active workflow, always resolve the correct node type name and parameters for this specific server.

**Primary method — MCP server (preferred):**

1. Call `search_nodes` with the service or node name (e.g. `"openai"`, `"wordpress"`, `"schedule trigger"`).
2. Note the node ID and discriminators (`resource`, `operation`, `mode`) returned.
3. Call `get_node_types` with the node ID and discriminators to get the exact TypeScript parameter definitions.
4. Use only the parameter names returned — never guess or assume field names.

The MCP server is connected via `.mcp.json` and available in every Claude Code session. The endpoints `/api/v1/node-types` and `/rest/node-types` are not available on this server — MCP is the only reliable programmatic source for node type definitions.

**Fallback — scan existing workflows (when MCP is unavailable):**

1. `GET /api/v1/workflows` + `GET /api/v1/workflows/{id}` for each — collect all `node.type` and `typeVersion` values already in use.
2. If the node is not found, consult official n8n documentation and ask the user to confirm the node exists in their n8n UI before writing JSON.

**Always collect `typeVersion`** — use the version already in use on the server, not a version assumed from documentation.

Apply this rule before every new node implementation, not only for AI/LLM nodes.


## Coding Standards

- All code written inside n8n workflow nodes (Code node, Function node, or any inline script block) must be written in **JavaScript** compatible with the n8n Code node runtime (server-side Node.js), not Python, unless the target n8n server is explicitly prepared with a working Python runner.
- Apply this rule to every new node and to any node modified during implementation.


## Excluded Directories
Always ignore these folders for review/refactoring/fixes:
- `vendor/`
- `node_modules/`
