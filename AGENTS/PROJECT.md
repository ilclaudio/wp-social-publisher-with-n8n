# WP Social Publisher Approval Flow — Agent Context

## Project Overview

This project manages **n8n automation workflows** stored as version-controlled JSON files. The goal is to maintain a single source of truth for all n8n workflows in a Git repository, enabling versioning, rollback, and automated deployment to an on-premise n8n server via its REST API.

The agent is expected to create, modify, and deploy n8n workflows by:
1. Writing/updating JSON workflow files locally
2. Deploying them to the n8n server via API
3. Committing and pushing changes to the remote Git repository

For any branch/commit/PR activity, use `AGENTS/GIT_WORKFLOW.md` as the single source of truth, including the mandatory sensitive-data checks before commit and the test-project exception that allows direct commits on `master`/`main` when already on those branches.

## Technology Stack

- DEV environment: Visual Studio Code (VSC) on Windows 11.
- n8n platform: use n8n version `>= 2.8.3`.
- Deployment/runtime environment: remote Ubuntu server `22.04.05`.

---

## Configuration Sources

| Variable | Scope | Description |
|---|---|---|
| `WSPAF_N8N_BASE_URL` | Development environment | Base URL of the n8n server (e.g. `http://192.168.1.100:5678`) |
| `WSPAF_N8N_API_KEY` | Development environment | API key for authenticating with the n8n REST API |
| `WSPAF_WP_SITE_URL` | n8n runtime environment | WordPress site base URL used to detect new posts |
| `WSPAF_APPROVAL_EMAIL` | n8n runtime environment | Approval recipient email address for channel publish decisions |
| `WSPAF_APPROVAL_NAME` | n8n runtime environment | Approval recipient display name used in emails |

Project naming rule: all environment variables must use the `WSPAF_` prefix.

Runtime split rule:
- Use `WSPAF_N8N_BASE_URL` and `WSPAF_N8N_API_KEY` in development environment for local API/deploy tooling.
- Use environment variables `WSPAF_WP_SITE_URL`, `WSPAF_APPROVAL_EMAIL`, and `WSPAF_APPROVAL_NAME` in workflow runtime expressions via `$env`.
- Use n8n `Credentials` for secrets and authenticated integrations.
Never hardcode any of these values in source files.

Credential ID portability rule: n8n credential IDs are instance-specific. In workflow JSON source files, always leave the credential `id` field as an empty string `""` and populate only the `name` field. Before deploying via API, resolve the actual ID with `GET /api/v1/credentials` and inject it into the request payload at deploy time — never commit a resolved ID to the repository.


> Never commit secrets, API keys, or `.env` files to Git.

---

## Project Structure

```
n8n-workflows/
│
├── .env                        # Environment variables (never committed)
├── .gitignore                  # Excludes .env, node_modules, etc.
├── README.md                   # Human-readable project documentation
├── AGENTS/
│   ├── PROJECT.md              # This file — agent instructions and context
│   └── GIT_WORKFLOW.md         # Branch, commit, and PR conventions
├── AGENTS.md                   # Codex/ChatGPT bootstrap instructions
├── CLAUDE.md                   # Claude bootstrap instructions
│
├── workflows/                  # All n8n workflow definitions as JSON
│   ├── active/                 # Workflows currently active on the server
│   │   └── test-manual-trigger-base.json
│   └── draft/                  # Workflows in development, not yet deployed
│       └── (empty)
```

---

## n8n API Reference

The n8n Public API must be enabled in `Settings → API`. All requests require the header:

```
X-N8N-API-KEY: <your-api-key>
```

### Key Endpoints

| Action | Method | Endpoint |
|---|---|---|
| List all workflows | `GET` | `/api/v1/workflows` |
| Get a workflow | `GET` | `/api/v1/workflows/{id}` |
| Create a workflow | `POST` | `/api/v1/workflows` |
| Update a workflow | `PUT` | `/api/v1/workflows/{id}` |
| Delete a workflow | `DELETE` | `/api/v1/workflows/{id}` |
| Activate a workflow | `POST` | `/api/v1/workflows/{id}/activate` |
| Deactivate a workflow | `POST` | `/api/v1/workflows/{id}/deactivate` |
| List executions | `GET` | `/api/v1/executions` |

---

## Workflow JSON Structure

Each workflow file in `workflows/` must follow the n8n JSON format. A typical local structure is:

```json
{
  "name": "Workflow Name",
  "nodes": [],
  "connections": {},
  "settings": {
    "executionOrder": "v1"
  },
  "staticData": null,
  "tags": []
}
```

When deploying a new workflow via `POST /api/v1/workflows`, do **not** include the `id` field.
When updating an existing workflow via `PUT`, include the `id` field and ensure it matches the endpoint.
When calling the API, exclude read-only fields from payload (for example `tags`, if enforced as read-only by server version).

---

## Agent Instructions

### When creating a new workflow

1. Understand the automation goal described by the user
2. Use `search_nodes` and `get_node_types` via MCP to resolve exact node IDs and parameter names
3. Generate the workflow JSON respecting the n8n node structure
4. Save the file in `workflows/draft/<workflow-name>.json`
5. Deploy it to the n8n server via `POST /api/v1/workflows`
6. If deployment is successful, move the file to `workflows/active/`
7. Optionally activate it via `POST /api/v1/workflows/{id}/activate`
8. Commit the new file with a descriptive message and push to remote

### When modifying an existing workflow

1. Read the existing JSON from `workflows/active/<workflow-name>.json`
2. For any new node, resolve type and parameters via MCP (`search_nodes` + `get_node_types`) before writing
3. Apply the requested changes
4. Update the workflow on the server via `scripts/deploy.ps1` (handles credential ID injection)
5. Save the updated JSON locally (overwrite the existing file)
6. Commit with a message describing what changed and push to remote

### When pulling workflows from the server

1. Call `GET /api/v1/workflows` to retrieve all workflows
2. For each workflow, save its JSON to `workflows/active/<name>.json`
3. Commit the pulled state as a snapshot and push to remote

---

## Existing Credentials on the Server

> Update this section with the credentials already configured in your n8n instance so the agent can reference them correctly when building workflows.

| Credential Name | Type | Used For |
|---|---|---|
| *(example) My Google Account* | Google OAuth2 | Google Sheets, Gmail |
| *(example) Slack Bot Token* | Slack API | Slack notifications |
| *(example) SMTP Server* | SMTP | Email sending |

---

## Naming Conventions

- Workflow file names: `kebab-case`, descriptive, e.g. `sync-crm-to-sheets.json`
- Workflow names inside JSON: `Title Case`, e.g. `"Sync CRM to Sheets"`
- Node names: descriptive of their action, e.g. `"Fetch New Leads"`, `"Send Slack Alert"`
- Tags: use tags inside n8n to categorize workflows (e.g. `reporting`, `sync`, `alerts`)

---

## Notes for the Agent

- All code inside n8n workflow nodes (Code node, Function node, or any inline script block) must be written in **JavaScript** compatible with the n8n Code node runtime (server-side Node.js), not Python, unless the target n8n server is explicitly prepared with a working Python runner.
- Always check if a workflow with the same name already exists before creating a new one (to avoid duplicates)
- Never hardcode sensitive values (API keys, passwords) inside workflow JSON — use n8n credentials instead
- Respect variable scope split: local tooling uses `WSPAF_N8N_BASE_URL`/`WSPAF_N8N_API_KEY`; workflow runtime uses `$env.WSPAF_WP_SITE_URL` and `$env.WSPAF_APPROVAL_*`
- For WordPress new-post detection, use publication date (`date_gmt`) as primary criterion
- For duplicate prevention, persist processed WordPress post IDs in n8n Data Store
- Support dual start paths when required: `Schedule Trigger` for production checks and `Manual Trigger` for test runs
- If a node requires a credential, reference the credential configured in n8n Credentials
- When in doubt about a node's configuration, prefer a simpler, working structure over a complex broken one
- After every deployment, verify the server returned a `200 OK` or `201 Created` response before committing
