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
- Use PowerShell first, not bash/WSL, to read `WSPAF_N8N_BASE_URL` and `WSPAF_N8N_API_KEY`.
- Deploy by updating the existing remote workflow via n8n API `PUT`, not by deleting and recreating it, unless the user explicitly asks otherwise.
- Default source file: `workflows/active/wp-social-publisher-approval-flow.json`, unless the user specifies a different workflow file.
- First identify the remote workflow by canonical name, then update that workflow in place.
- Exclude read-only fields from the request body.
- After deploy, verify with a follow-up `GET` that the remote workflow reflects the expected changes.
- Do not activate or deactivate the workflow unless the user explicitly requests it.
- At the end, report the workflow ID, whether it was updated in place, and the verification result.


## n8n Node Type Resolution

Before implementing any node not yet present in the active workflow, always resolve the correct node type name for this specific server:

1. **Scan existing workflows first**: `GET /api/v1/workflows` + `GET /api/v1/workflows/{id}` for each — collect all `node.type` values already in use. This is the only reliable programmatic source available on this server.
2. **If the needed node is not found in existing workflows**: consult the official n8n documentation to identify the correct package (`n8n-nodes-base.*` vs `@n8n/n8n-nodes-langchain.*` vs community packages) and ask the user to confirm the node exists in their n8n UI before writing JSON.
3. **Never assume `n8n-nodes-base.*`**: this server uses `@n8n/n8n-nodes-langchain.*` for AI/LLM nodes. The endpoints `/api/v1/node-types` and `/rest/node-types` are not available on this server.
4. **Also collect `typeVersion`** from existing workflow nodes — use the version already in use on the server, not a version assumed from documentation.

Apply this rule before every new node implementation, not only for AI/LLM nodes.


## Coding Standards

- All code written inside n8n workflow nodes (Code node, Function node, or any inline script block) must be written in **JavaScript** compatible with the n8n Code node runtime (server-side Node.js), not Python, unless the target n8n server is explicitly prepared with a working Python runner.
- Apply this rule to every new node and to any node modified during implementation.


## Excluded Directories
Always ignore these folders for review/refactoring/fixes:
- `vendor/`
- `node_modules/`
