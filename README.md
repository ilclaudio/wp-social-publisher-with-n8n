# WP Social Publisher Approval Flow
Publish WordPress posts on social channels with approval gating.

Configuration must use environment variables with the `WSPAF_` project prefix.

- Primary AI connection path: n8n MCP server.
- Development environment fallback (local tooling/API scripts): `WSPAF_N8N_BASE_URL`, `WSPAF_N8N_API_KEY`.
- n8n runtime environment variables (workflow execution): `WSPAF_WP_SITE_URL`, `WSPAF_APPROVAL_EMAIL`, `WSPAF_APPROVAL_NAME`, `WSPAF_SENDER_EMAIL`.
- n8n Credentials: OpenAI, SMTP, and social platform secrets/tokens.
- Workflow code should target the n8n Code node JavaScript runtime (server-side Node.js) unless the server is explicitly configured with a working Python runner.

## MCP Server integration

This project uses the n8n Instance-level MCP server, configured in `.mcp.json` (not committed — contains a JWT token). Claude Code connects automatically to the MCP endpoint at session start.

MCP is the preferred path for AI-assisted **development**: node discovery, validation, and workflow inspection. **Deploy uses the REST API** (`scripts/deploy.ps1`) as the primary path; MCP `update_workflow` is the fallback when the REST API is unavailable.

**Why REST API for deploy:** the local workflow JSON is already maintained in `workflows/active/`. The REST deploy sends it directly with credential ID injection — no format conversion needed. MCP `update_workflow` requires rewriting the full workflow in SDK TypeScript at deploy time and also requires the "Available in MCP" toggle enabled on the target workflow.

**Why MCP for development:** the n8n REST API does not expose a reliable `/node-types` endpoint on this server instance. The MCP server fills that gap:

- `search_nodes` / `get_node_types` — resolve exact node IDs and parameter names before writing workflow code, eliminating guesswork.
- `validate_workflow` — validate SDK code before deploying, catching errors locally.
- `get_workflow_details` — read the live workflow state from the server, always in sync.
- `execute_workflow` / `get_execution` — run and inspect executions for testing without opening the n8n UI.

See [DOC/n8n-mcp-vscode-setup.md](DOC/n8n-mcp-vscode-setup.md) for the full setup procedure.

## Variable roles

- `WSPAF_N8N_BASE_URL` and `WSPAF_N8N_API_KEY` are no longer the primary connection method when MCP is available, but they still make sense for fallback REST access and local deployment scripts.
- `WSPAF_WP_SITE_URL`, `WSPAF_APPROVAL_EMAIL`, `WSPAF_APPROVAL_NAME`, and `WSPAF_SENDER_EMAIL` remain part of the workflow runtime design and must stay configured on the remote n8n server.
- Secrets and authenticated integrations must stay in n8n Credentials, not in workflow JSON or Markdown files.

## Current workflow nodes

### Main flow

| Node | Type | What it does |
|---|---|---|
| `Manual Trigger` | Trigger | Starts the workflow on demand for tests. |
| `Schedule Trigger (Hourly)` | Trigger | Starts the workflow automatically every hour. |
| `Fetch WP Posts` | HTTP Request | Calls the WordPress REST API (`$env.WSPAF_WP_SITE_URL`) and fetches the 20 most recent published posts, including `_embedded` data for featured media. Both triggers connect directly to this node. |
| `Debug - Count fetched posts` | Code | Logs the number of posts returned and a short preview of the first items. |
| `Detect New Posts (date_gmt)` | Code | Keeps only posts published within the last 70 minutes (based on `date_gmt`). Adds `detectedAtUtc` to each item. |
| `Deduplicate via Data Store` | Remove Duplicates | Skips posts whose WordPress `id` was already seen in a previous execution (workflow-scope persistent history, up to 10 000 entries). |
| `Debug - Deduplicate summary` | Code | Logs how many posts were detected, kept, and skipped as duplicates. |
| `Extract URL and Featured Image` | Code | Normalises each post into clean fields: `titleText`, `excerptText`, `postUrl`, `imageUrl`, `hasFeaturedImage`. Strips HTML tags and decodes entities from title and excerpt. `imageUrl` is a URL string only — no binary is downloaded here. Twitter/X and Instagram will need a separate HTTP Request node to fetch the binary before uploading; Telegram and Facebook can use the URL directly. |
| `Generate AI Message (max 280, #n8n)` | `@n8n/n8n-nodes-langchain.openAi` v2.1 | Calls OpenAI `gpt-4o-mini` via Responses API (credential `OpenAI account`). System instructions enforce max 280 chars, `#n8n` hashtag, URL at the end, and language matching the post title. Input: `titleText`, `excerptText`, `postUrl`. |
| `Validate AI Message` | Code | Guarantees the AI output respects the constraints regardless of what OpenAI returned. Injects `#n8n` if missing, truncates to 280 chars preserving URL and hashtag. Adds `socialMessage`, `socialMessageLength`, `socialMessageValid` to the payload. |
| `Debug - AI message` | Code | Logs the final `socialMessage` text, length, and validity for each post. Visible in the node's **Logs** tab in the n8n execution detail view. |
| `Approval Gate (Email)` | `n8n-nodes-base.emailSend` v2.1 `sendAndWait` | Sends an HTML approval email from `$env.WSPAF_SENDER_EMAIL` to `$env.WSPAF_APPROVAL_EMAIL` with post title, URL, optional image link, and the generated social message. Buttons: **Pubblica** (approve) / **Non pubblicare** (reject). Waits up to 24 hours; if no response is received, execution resumes automatically and is treated as rejected. Credential: `SMTP account`. |
| `Approved?` | `n8n-nodes-base.if` v2.3 | Branches on `$json.approved`. Output 0 (true) → publish. Output 1 (false/timeout) → skip. |
| `Has Image? (Twitter)` | `n8n-nodes-base.if` v2.2 | Checks `$('Validate AI Message').item.json.hasFeaturedImage`. Note: `$json` after `sendAndWait` contains only the approval response, so post data must be read from the upstream node explicitly. True → image path (3 nodes). False → `Post Tweet` directly. |
| `Fetch Image Binary` | HTTP Request | Downloads the featured image as binary data (`responseFormat: file`) to prepare it for upload. |
| `Upload Media to Twitter` | HTTP Request | POSTs the binary to `upload.twitter.com/1.1/media/upload.json` with OAuth1 (`X OAuth account`). Returns `media_id_string`. Media upload is a v1.1-only endpoint available on the free X API tier. |
| `Post Tweet with Image` | `n8n-nodes-base.twitter` v2 | Publishes the tweet using the native X node with `X OAuth2 account`. Text from `Validate AI Message`, media ID from the upload step. |
| `Post Tweet` | `n8n-nodes-base.twitter` v2 | Same native X node, without media attachment. Used when the post has no featured image. |
| `Skip - Not Approved` | NoOp | Reached when the approval is rejected or the 24-hour timeout expires. No action taken. |

**Credential split:** media upload uses `X OAuth account` (OAuth1) because `upload.twitter.com` is a v1.1 endpoint that requires OAuth1. Tweet posting uses `X OAuth2 account` (OAuth2) with the native X node, because the X free API tier only allows tweet creation via v2 endpoints, and the native n8n Twitter node requires OAuth2.

### Maintenance branch (separate from main flow)

| Node | What it does |
|---|---|
| `Manual Trigger (Clear Dedupe History)` | Starts a standalone maintenance branch. |
| `Clear Dedupe History` | Resets the workflow-scope deduplication history (useful during debugging to re-process already-seen posts). |
| `Debug - Clear dedupe history` | Logs a confirmation payload after the reset. |

### Twitter/X credential setup

1. Create a developer account at [developer.twitter.com](https://developer.twitter.com) and create a new App.
2. In the App settings, open **User authentication settings** and configure:
   - App permissions: **Read and Write**
   - Type of App: **Web App**
   - Callback URI: `https://<your-n8n-domain>/rest/oauth1-credential/callback`
   - Enable **only OAuth 1.0a** — enabling OAuth 2.0 at the same time causes a 403 error during authorization.
3. From **Keys and Tokens**, copy: API Key, API Secret Key, Access Token, Access Token Secret.
4. In n8n → Credentials → Add → **X OAuth1 API** — paste the four values and save as `Twitter account`.

The Free API tier (1 500 tweets/month write-only) is sufficient for this workflow.

### Credential deploy note

The `Generate AI Message` node stores an empty `id` in the local JSON for the `OpenAI account` credential. The deploy script (`scripts/deploy.ps1`) resolves the actual credential ID at deploy time via `GET /api/v1/credentials` and injects it into the request payload. Never hardcode the ID in the source file — it is instance-specific.

## Remote deploy procedure

When the workflow is updated on the n8n server, the deploy process updates the existing remote workflow in place instead of deleting and recreating it.

This REST-based deploy procedure is the primary deployment path for this project. Use MCP `update_workflow` only as fallback when the REST API path is unavailable.

Steps:

- Read the remote workflow list from the n8n API.
- Identify the target workflow by its canonical workflow name.
- Read the local source file from `workflows/active/`.
- Send a `PUT` request to the remote workflow endpoint using the remote workflow identifier returned by the API.
- Exclude read-only fields from the request body.
- Run a final verification request to confirm that the remote workflow reflects the expected changes.
