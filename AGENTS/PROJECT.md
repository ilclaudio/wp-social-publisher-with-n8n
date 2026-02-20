# N8N Workflow Management Project — Agent Context

## Project Overview

This project manages **n8n automation workflows** stored as version-controlled JSON files. The goal is to maintain a single source of truth for all n8n workflows in a Git repository, enabling versioning, rollback, and automated deployment to an on-premise n8n server via its REST API.

The agent is expected to create, modify, and deploy n8n workflows by:
1. Writing/updating JSON workflow files locally
2. Deploying them to the n8n server via API
3. Committing and pushing changes to the remote Git repository

For any branch/commit/PR activity, use `AGENTS/GIT_WORKFLOW.md` as the single source of truth, including the mandatory sensitive-data checks before commit and the test-project exception that allows direct commits on `master`/`main` when already on those branches.

---

## Environment

| Variable | Description |
|---|---|
| `N8N_BASE_URL` | Base URL of the n8n server (e.g. `http://192.168.1.100:5678`) |
| `N8N_API_KEY` | API key for authenticating with the n8n REST API |
| `N8N_GIT_REMOTE` | Remote repository URL (e.g. `https://github.com/user/n8n-workflows`) |

These values must be read from Windows environment variables (User or System scope), not hardcoded in source files.

PowerShell example:

```powershell
[Environment]::SetEnvironmentVariable("N8N_BASE_URL", "http://192.168.1.100:5678", "User")
[Environment]::SetEnvironmentVariable("N8N_API_KEY", "your-api-key", "User")
[Environment]::SetEnvironmentVariable("N8N_GIT_REMOTE", "https://github.com/user/n8n-workflows", "User")
```

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
│   │   ├── report-weekly.json
│   │   └── sync-email-sheets.json
│   └── draft/                  # Workflows in development, not yet deployed
│       └── new-workflow.json
│
├── scripts/                    # Utility scripts for interacting with n8n API
│   ├── deploy.js               # Deploy one or all workflows from local to n8n
│   ├── pull.js                 # Pull all workflows from n8n and save locally
│   ├── activate.js             # Activate a workflow by ID or name
│   └── list.js                 # List all workflows currently on the server
│
├── credentials/                # (Optional) Reference list of available credentials
│   └── credentials-map.md      # Maps credential names to their n8n IDs
│
└── docs/                       # Additional documentation
    ├── workflow-conventions.md  # Naming conventions and design patterns
    └── changelog.md            # Manual log of major changes
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

Each workflow file in `workflows/` must follow the n8n JSON format. The minimal required fields are:

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

When deploying a new workflow via `POST /api/v1/workflows`, do **not** include the `id` field. When updating an existing workflow via `PUT`, include the `id` field and ensure it matches the endpoint.

---

## Agent Instructions

### When creating a new workflow

1. Understand the automation goal described by the user
2. Generate the workflow JSON respecting the n8n node structure
3. Save the file in `workflows/draft/<workflow-name>.json`
4. Deploy it to the n8n server via `POST /api/v1/workflows`
5. If deployment is successful, move the file to `workflows/active/`
6. Optionally activate it via `POST /api/v1/workflows/{id}/activate`
7. Commit the new file with a descriptive message and push to remote

### When modifying an existing workflow

1. Read the existing JSON from `workflows/active/<workflow-name>.json`
2. Apply the requested changes
3. Update the workflow on the server via `PUT /api/v1/workflows/{id}`
4. Save the updated JSON locally (overwrite the existing file)
5. Commit with a message describing what changed and push to remote

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

- Always check if a workflow with the same name already exists before creating a new one (to avoid duplicates)
- Never hardcode sensitive values (API keys, passwords) inside workflow JSON — use n8n credentials instead
- If a node requires a credential, reference it by the credential name listed in the credentials map above
- When in doubt about a node's configuration, prefer a simpler, working structure over a complex broken one
- After every deployment, verify the server returned a `200 OK` or `201 Created` response before committing
