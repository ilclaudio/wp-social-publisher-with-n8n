# WP Social Publisher Approval Flow

Automation that detects newly published WordPress posts, generates a social message with AI, requests human approval by email, and publishes to X (Twitter) only after explicit approval.

## What it does

When a new post is published on a WordPress site, the workflow:

1. Detects it automatically (daily at 06:00, or on manual trigger)
2. Extracts title, excerpt, URL, and featured image
3. Generates a short social message via OpenAI (max 280 chars, `#n8n` hashtag, post language)
4. Sends an approval email with post details and the AI-generated text
5. Waits for a human decision (up to 24 hours):
   - **Pubblica** → publishes the tweet (with image if available)
   - **Non pubblicare** or no response → skips publication
6. Sends a confirmation email with the outcome

## Prerequisites

Before setting up this workflow you need:

- A self-hosted **n8n** instance (tested on Ubuntu 22.04)
- A **WordPress** site with REST API enabled
- An **OpenAI** account with API access
- An **SMTP** server or account for sending emails
- An **X (Twitter) developer account** with an app configured for both OAuth1 and OAuth2

## Repository structure

```
workflows/
  active/     # source of truth for the deployed workflow
  draft/      # work in progress
  backup/     # timestamped snapshots before each change
scripts/
  deploy.ps1  # deploys the active workflow to n8n via REST API
AGENTS/       # instructions and context for AI assistants
DOC/          # setup guides and notes
```

## Setup

### 1. Configure n8n environment variables

Set these variables on your n8n server (Settings → Environment variables or docker-compose env):

| Variable | Description |
|---|---|
| `WSPAF_WP_SITE_URL` | WordPress base URL (e.g. `https://example.com`) |
| `WSPAF_APPROVAL_EMAIL` | Email address that receives approval requests |
| `WSPAF_APPROVAL_NAME` | Display name of the approval recipient |
| `WSPAF_SENDER_EMAIL` | From address used for all workflow emails |

### 2. Create n8n credentials

Create these credentials in n8n (Settings → Credentials):

| Credential name | Type | Used by |
|---|---|---|
| `OpenAI account` | OpenAI API | AI message generation |
| `SMTP Account` | SMTP | Approval and notification emails |
| `X OAuth account` | X OAuth1 API | Media upload to Twitter |
| `X OAuth2 account` | X OAuth2 API | Tweet creation |

See the [Twitter/X credential setup](#twitterx-credential-setup) section for the full X developer app configuration.

### 3. Configure local tooling (for deploy only)

**Generate the n8n REST API key:** in the n8n UI go to Settings → API → Generate API Key. Copy the key — you will only see it once.

**Set the following machine-level environment variables** on your development machine:

| Variable | Description |
|---|---|
| `WSPAF_N8N_BASE_URL` | n8n base URL (e.g. `https://n8n.example.com`) |
| `WSPAF_N8N_API_KEY` | n8n REST API key generated above |

On **Windows** (run as Administrator, then restart the terminal):
```cmd
setx WSPAF_N8N_BASE_URL "https://n8n.example.com" /M
setx WSPAF_N8N_API_KEY your-api-key /M
```

On **Linux / macOS** (add to `~/.bashrc` or `~/.zshrc`):
```bash
export WSPAF_N8N_BASE_URL="https://n8n.example.com"
export WSPAF_N8N_API_KEY=your-api-key
```

### 4. Create the workflow in n8n for the first time

`deploy.ps1` updates an **existing** workflow by name. On a fresh n8n instance you must create it manually first:

1. In the n8n UI go to **Workflows → New workflow**.
2. Rename it to exactly: `WP Social Publisher Approval Flow`
3. Save it (it can be empty — the deploy script will populate it).

> On subsequent deploys this step is not needed.

### 5. Deploy the workflow

The deploy script requires **PowerShell** (included on Windows; install [PowerShell Core](https://github.com/PowerShell/PowerShell) on Linux/macOS).

```powershell
.\scripts\deploy.ps1
```

The script resolves credential IDs from the target n8n instance, injects them into the payload, sends a `PUT` request, and verifies the remote workflow reflects the expected state.

### 6. Configure allowed domains on the X OAuth account credential

After creating the `X OAuth account` (OAuth1) credential, you must allow the Twitter API domains:

1. In n8n → Credentials → open `X OAuth account`
2. Find the **Allowed HTTP Request Domains** field
3. Add: `api.twitter.com` and `upload.twitter.com`
4. Save

Without this step n8n will block HTTP Request nodes from signing requests to those domains.

### 7. Activate the workflow

In the n8n UI, open the workflow and toggle it to **Active**. The schedule trigger will fire daily at 06:00.

---

## Testing

To test the flow without waiting for the next scheduled execution:

1. Open the workflow in the n8n UI.
2. Click **Manual Trigger → Execute step** — this runs the full flow from post detection through to the approval email.
3. Check your inbox and click **Pubblica** or **Non pubblicare**.
4. The execution resumes and completes the relevant branch.

To test individual nodes after the approval gate (which uses `sendAndWait` and cannot be bypassed with "Execute step"):

1. Click on `Has Image? (Twitter)`, `Post Tweet`, or any downstream node.
2. Add **Pin data** with a sample payload containing `hasFeaturedImage`, `socialMessage`, `imageUrl`, `postUrl`, `titleText`.
3. Click **Execute step** on that node — execution starts from the pinned node, skipping everything upstream including the approval gate.

---

## Current workflow nodes

### Main flow

| Node | Type | What it does |
|---|---|---|
| `Manual Trigger` | Trigger | Starts the workflow on demand for tests. |
| `Schedule Trigger (Daily 06:00)` | Trigger | Starts the workflow automatically once per day at 06:00. |
| `Fetch WP Posts` | HTTP Request | Calls the WordPress REST API (`$env.WSPAF_WP_SITE_URL`) and fetches the 20 most recent published posts, including `_embedded` data for featured media. Both triggers connect directly to this node. |
| `Debug - Count fetched posts` | Code | Logs the number of posts returned and a short preview of the first items. |
| `Detect New Posts (date_gmt)` | Code | Keeps only posts published within the last 1500 minutes (25 hours) based on `date_gmt`. Adds `detectedAtUtc` to each item. |
| `Deduplicate via Data Store` | Remove Duplicates | Skips posts whose WordPress `id` was already seen in a previous execution (workflow-scope persistent history, up to 10 000 entries). |
| `Debug - Deduplicate summary` | Code | Logs how many posts were detected, kept, and skipped as duplicates. |
| `Extract URL and Featured Image` | Code | Normalises each post into clean fields: `titleText`, `excerptText`, `postUrl`, `imageUrl`, `hasFeaturedImage`. Strips HTML tags and decodes entities (including numeric ones like `&#8211;`) from title and excerpt. |
| `Generate AI Message (max 280, #n8n)` | `@n8n/n8n-nodes-langchain.openAi` v2.1 | Calls OpenAI `gpt-4o-mini` via Responses API (credential `OpenAI account`). System instructions enforce max 280 chars, `#n8n` hashtag, URL at the end, and language matching the post title. Input: `titleText`, `excerptText`, `postUrl`. |
| `Validate AI Message` | Code | Guarantees the AI output respects the constraints regardless of what OpenAI returned. Injects `#n8n` if missing, truncates to 280 chars preserving URL and hashtag. Adds `socialMessage`, `socialMessageLength`, `socialMessageValid` to the payload. |
| `Debug - AI message` | Code | Logs the final `socialMessage` text, length, and validity for each post. Visible in the node's **Logs** tab in the n8n execution detail view. |
| `Approval Gate (Email)` | `n8n-nodes-base.emailSend` v2.1 `sendAndWait` | Sends an HTML approval email from `$env.WSPAF_SENDER_EMAIL` to `$env.WSPAF_APPROVAL_EMAIL` with post title, URL, optional image link, and the generated social message. Buttons: **Pubblica** (approve) / **Non pubblicare** (reject). Waits up to 24 hours; if no response is received, execution resumes automatically and is treated as rejected. Credential: `SMTP Account`. |
| `Approved?` | `n8n-nodes-base.if` v2.3 | Branches directly on `$json.data.approved` from the `sendAndWait` response. Output 0 (true) → publish. Output 1 (false/timeout) → skip. |
| `Has Image? (Twitter)` | `n8n-nodes-base.if` v2.2 | Checks `hasFeaturedImage` from the upstream `Validate AI Message` node (post data must be read explicitly since `$json` after `sendAndWait` contains only the approval response). True → image path. False → `Post Tweet` directly. |
| `Fetch Image Binary` | HTTP Request | Downloads the featured image as binary data to prepare it for upload. |
| `Upload Media to Twitter` | HTTP Request | POSTs the binary to `upload.twitter.com/1.1/media/upload.json` with OAuth1 (`X OAuth account`). Returns `media_id_string`. |
| `Post Tweet with Image` | `n8n-nodes-base.twitter` v2 | Publishes the tweet using the native X node with `X OAuth2 account`. Text from `Validate AI Message`, media ID from the upload step. |
| `Post Tweet` | `n8n-nodes-base.twitter` v2 | Same native X node, without media attachment. Used when the post has no featured image. |
| `Skip - Not Approved` | NoOp | Reached when the approval is rejected or the 24-hour timeout expires. No action taken. |
| `Notify - Published with Image` | `n8n-nodes-base.emailSend` v2.1 | Sends a confirmation email after a successful X post with image. Subject includes explicit status and WordPress post ID. |
| `Notify - Published without Image` | `n8n-nodes-base.emailSend` v2.1 | Sends a confirmation email after a successful X post without image. Subject includes explicit status and WordPress post ID. |
| `Notify - Not Approved` | `n8n-nodes-base.emailSend` v2.1 | Sends a notification email when approval is rejected or expires. Subject includes explicit status and WordPress post ID. |

### Maintenance branch (separate from main flow)

| Node | What it does |
|---|---|
| `Manual Trigger (Clear Dedupe History)` | Starts a standalone maintenance branch. |
| `Clear Dedupe History` | Resets the workflow-scope deduplication history (useful during debugging to re-process already-seen posts). |
| `Debug - Clear dedupe history` | Logs a confirmation payload after the reset. |

---

## Twitter/X credential setup

This workflow uses two separate X credentials because media upload and tweet creation use different API families.

**OAuth1 credential** (for media upload — v1.1 API, free tier):
1. Create a developer account at [developer.twitter.com](https://developer.twitter.com) and create a new App.
2. In **User authentication settings** configure:
   - App permissions: **Read and Write**
   - Type of App: **Web App**
   - Callback URI: `https://<your-n8n-domain>/rest/oauth1-credential/callback`
   - Enable **only OAuth 1.0a** — enabling OAuth 2.0 simultaneously causes a 403 during authorization.
3. From **Keys and Tokens**, copy: API Key, API Secret Key, Access Token, Access Token Secret.
4. In n8n → Credentials → Add → **X OAuth1 API** → save as `X OAuth account`.

**OAuth2 credential** (for tweet creation — v2 API, required by free tier):
1. In the same X app, enable **OAuth 2.0** (you can do this after completing the OAuth1 setup above).
2. Set the callback URI required by n8n: `https://<your-n8n-domain>/rest/oauth2-credential/callback`.
3. In n8n → Credentials → Add → **X OAuth2 API** → save as `X OAuth2 account`.

**Why two credentials:** the X free API tier allows tweet creation only via v2 endpoints, which require OAuth2. Media upload is only available via v1.1, which requires OAuth1. The native n8n Twitter node uses OAuth2; the media upload node is an HTTP Request using OAuth1 directly.

| Node | Auth type | Credential |
|---|---|---|
| `Upload Media to Twitter` | OAuth1 | `X OAuth account` |
| `Post Tweet with Image` | OAuth2 | `X OAuth2 account` |
| `Post Tweet` | OAuth2 | `X OAuth2 account` |

---

## Deploy procedure

`scripts/deploy.ps1` is the only deploy tool in this repository. It pushes the local workflow JSON to an existing n8n workflow via the n8n REST API.

**What it does, step by step:**

1. Reads `WSPAF_N8N_BASE_URL` and `WSPAF_N8N_API_KEY` from machine-level environment variables.
2. Calls `GET /api/v1/credentials` on the target n8n instance and resolves the IDs of the four required credentials by name (`OpenAI account`, `SMTP Account`, `X OAuth account`, `X OAuth2 account`).
3. Calls `GET /api/v1/workflows` and finds the remote workflow named `WP Social Publisher Approval Flow`.
4. Loads `workflows/active/wp-social-publisher-approval-flow.json` from disk.
5. Injects the resolved credential IDs into the matching nodes in the payload (credential IDs are instance-specific and must never be hardcoded in the source file).
6. Sends a `PUT /api/v1/workflows/{id}` request to overwrite the remote workflow with the local one.
7. Fetches the workflow back from the server and verifies that key nodes are present.

**Prerequisite:** the workflow must already exist on the n8n instance with the exact name above (see [step 4 of Setup](#4-create-the-workflow-in-n8n-for-the-first-time)). The script updates an existing workflow — it does not create one.

---

## MCP server integration

This project uses the n8n Instance-level MCP server for AI-assisted development. Configure it in `.mcp.json` (not committed — contains a JWT token). Claude Code connects automatically at session start.

MCP is used for **development**: node discovery, validation, and workflow inspection.  
REST API (`scripts/deploy.ps1`) is used for **deployment**.

| Tool | Purpose |
|---|---|
| `search_nodes` / `get_node_types` | Resolve exact node IDs and parameter names |
| `validate_workflow` | Validate workflow code before deploying |
| `get_workflow_details` | Read live workflow state from the server |
| `execute_workflow` / `get_execution` | Run and inspect executions for testing |

See [DOC/n8n-mcp-claude-code-setup.md](DOC/n8n-mcp-claude-code-setup.md) for the full setup procedure.

---

## Environment variable reference

| Variable | Scope | Description |
|---|---|---|
| `WSPAF_N8N_BASE_URL` | Local dev / scripts | n8n base URL for REST API access |
| `WSPAF_N8N_API_KEY` | Local dev / scripts | n8n REST API key |
| `WSPAF_WP_SITE_URL` | n8n runtime | WordPress base URL |
| `WSPAF_APPROVAL_EMAIL` | n8n runtime | Approval recipient email address |
| `WSPAF_APPROVAL_NAME` | n8n runtime | Approval recipient display name |
| `WSPAF_SENDER_EMAIL` | n8n runtime | Sender address for all workflow emails |

Secrets and authenticated integrations must stay in n8n Credentials — never in workflow JSON or repository files.
