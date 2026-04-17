# WP Social Publisher Approval Flow
Publish WordPress posts on social channels with approval gating.

Configuration must use environment variables with the `WSPAF_` project prefix.

- Development environment (local tooling/API scripts): `WSPAF_N8N_BASE_URL`, `WSPAF_N8N_API_KEY`.
- n8n runtime environment variables (workflow execution): `WSPAF_WP_SITE_URL`, `WSPAF_APPROVAL_EMAIL`, `WSPAF_APPROVAL_NAME`.
- n8n Credentials: OpenAI, SMTP, and social platform secrets/tokens.
- Workflow code should target the n8n Code node JavaScript runtime (server-side Node.js) unless the server is explicitly configured with a working Python runner.

## MCP Server integration

This project uses the n8n Instance-level MCP server, configured in `.mcp.json` (not committed — contains a JWT token). Claude Code connects automatically to the MCP endpoint at session start.

**Why:** the n8n REST API does not expose a reliable `/node-types` endpoint on this server instance. The MCP server fills that gap and also streamlines the full development loop:

- `search_nodes` / `get_node_types` — resolve exact node IDs and parameter names before writing workflow code, eliminating guesswork.
- `validate_workflow` — validate SDK code before deploying, catching errors locally.
- `update_workflow` — deploy changes to the server directly from the chat, without running PowerShell scripts.
- `get_workflow_details` — read the live workflow state from the server, always in sync.
- `execute_workflow` / `get_execution` — run and inspect executions for testing without opening the n8n UI.

See [DOC/n8n-mcp-vscode-setup.md](DOC/n8n-mcp-vscode-setup.md) for the full setup procedure.

## Current workflow nodes

### Main flow

| Node | Type | What it does |
|---|---|---|
| `Manual Trigger` | Trigger | Starts the workflow on demand for tests. |
| `Schedule Trigger (Hourly)` | Trigger | Starts the workflow automatically every hour. |
| `Start (Manual or Hourly)` | NoOp | Merges the two trigger paths into one execution path. |
| `Fetch WP Posts` | HTTP Request | Calls the WordPress REST API (`$env.WSPAF_WP_SITE_URL`) and fetches the 20 most recent published posts, including `_embedded` data for featured media. |
| `Debug - Count fetched posts` | Code | Logs the number of posts returned and a short preview of the first items. |
| `Detect New Posts (date_gmt)` | Code | Keeps only posts published within the last 70 minutes (based on `date_gmt`). Adds `detectedAtUtc` to each item. |
| `Deduplicate via Data Store` | Remove Duplicates | Skips posts whose WordPress `id` was already seen in a previous execution (workflow-scope persistent history, up to 10 000 entries). |
| `Debug - Deduplicate summary` | Code | Logs how many posts were detected, kept, and skipped as duplicates. |
| `Extract URL and Featured Image` | Code | Normalises each post into clean fields: `titleText`, `excerptText`, `postUrl`, `imageUrl`, `hasFeaturedImage`. Strips HTML tags and decodes entities from title and excerpt. |
| `Generate AI Message (max 280, #n8n)` | `@n8n/n8n-nodes-langchain.openAi` | Calls OpenAI `gpt-4o-mini` (credential `OpenAI account`) with a system prompt that enforces max 280 chars, `#n8n` hashtag, URL at the end, and language matching the post title. Input: `titleText`, `excerptText`, `postUrl`. |
| `Validate AI Message` | Code | Guarantees the AI output respects the constraints regardless of what OpenAI returned. Injects `#n8n` if missing, truncates to 280 chars preserving URL and hashtag. Adds `socialMessage`, `socialMessageLength`, `socialMessageValid` to the payload. |
| `Debug - AI message` | Code | Logs the final `socialMessage` text, length, and validity for each post. Visible in the node's **Logs** tab in the n8n execution detail view. |
| `Approval Gate (Email)` | — | **Placeholder** — not implemented. Will send an approval request email per channel. |
| `Publish to Twitter/X` | — | **Placeholder** — not implemented. Will publish approved content to Twitter/X. |

### Maintenance branch (separate from main flow)

| Node | What it does |
|---|---|
| `Manual Trigger (Clear Dedupe History)` | Starts a standalone maintenance branch. |
| `Clear Dedupe History` | Resets the workflow-scope deduplication history (useful during debugging to re-process already-seen posts). |
| `Debug - Clear dedupe history` | Logs a confirmation payload after the reset. |

### Credential deploy note

The `Generate AI Message` node stores an empty `id` in the local JSON for the `OpenAI account` credential. The deploy script (`scripts/deploy.ps1`) resolves the actual credential ID at deploy time via `GET /api/v1/credentials` and injects it into the request payload. Never hardcode the ID in the source file — it is instance-specific.

## Remote deploy procedure

When the workflow is updated on the n8n server, the deploy process updates the existing remote workflow in place instead of deleting and recreating it.

Steps:

- Read the remote workflow list from the n8n API.
- Identify the target workflow by its canonical workflow name.
- Read the local source file from `workflows/active/`.
- Send a `PUT` request to the remote workflow endpoint using the remote workflow identifier returned by the API.
- Exclude read-only fields from the request body.
- Run a final verification request to confirm that the remote workflow reflects the expected changes.
