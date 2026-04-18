# WP Social Publisher Approval Flow — Project Context

## Purpose

This file is the project-specific source of truth for:
- workflow purpose and scope
- environment and runtime variables
- MCP vs REST usage in this repository
- deploy and backup conventions
- repository paths and canonical workflow names

Reusable AI behavior belongs in `AGENTS/AI_BEHAVIOR.md`.
Reusable Git rules belong in `AGENTS/GIT_WORKFLOW.md`.
Roadmap and progress belong in `AGENTS/IMPLEMENTATION_TRACK.md`.

## Project Overview

This repository stores version-controlled n8n workflows for a WordPress-to-social publishing flow with email approval.

Primary goal:
- detect newly published WordPress posts
- extract the publishable payload
- generate a short AI social message
- request approval by email
- publish only after approval

## Environment and Runtime Model

Project naming rule:
- all environment variables use the `WSPAF_` prefix

Connection model:
- MCP is the primary AI-session integration path for discovery, validation, and inspection
- REST API (`scripts/deploy.ps1`) is the primary deploy path; MCP `update_workflow` is the fallback when REST is unavailable
- workflow runtime values are read on the remote n8n server via `$env.<NAME>`

Variable scope:

| Variable | Scope | Use |
|---|---|---|
| `WSPAF_N8N_BASE_URL` | local development / fallback tooling | base URL for direct REST/API access |
| `WSPAF_N8N_API_KEY` | local development / fallback tooling | API key for direct REST/API access |
| `WSPAF_WP_SITE_URL` | remote n8n runtime | WordPress base URL used by the workflow |
| `WSPAF_APPROVAL_EMAIL` | remote n8n runtime | approval recipient email |
| `WSPAF_APPROVAL_NAME` | remote n8n runtime | approval recipient display name |
| `WSPAF_SENDER_EMAIL` | remote n8n runtime | sender email address for approval emails |

Rules:
- Do not remove runtime variables just because MCP is available.
- Use n8n Credentials for secrets and authenticated integrations.
- Never commit resolved credential IDs, secrets, or `.env` files.

## Runtime Notes

- Local development environment: Windows 11 with VS Code.
- Remote n8n runtime: Ubuntu `22.04.05`.
- When checking `WSPAF_*` variables or testing direct REST connectivity, try PowerShell first, then bash/WSL if needed.
- All code written inside n8n workflow script nodes must be JavaScript compatible with the n8n server runtime.

## Repository Paths and Workflow Files

- Active workflows: `workflows/active/`
- Draft workflows: `workflows/draft/`
- Backups: `workflows/backup/`
- Default active workflow file: `workflows/active/wp-social-publisher-approval-flow.json`
- Keep the canonical workflow name in the active JSON unless the user explicitly asks for a rename.

Backup rule for active workflow changes:
1. Copy the current active workflow to `workflows/backup/`.
2. Append `_yyyymmdd` before the `.json` extension.
3. Only then replace or modify the active file.

## Deploy Rules

Before any server-side deploy, activation, deactivation, or import-equivalent action:
- ask for explicit user confirmation
- wait for approval unless the user uses one of the approved deploy trigger phrases below

Approved deploy trigger phrases:
- `Aggiorna il flusso sul server`
- `Fai il deploy del flusso sul server`
- `Update the workflow on the server`
- `Deploy the workflow to the server`

When one of those trigger phrases is used:
1. Treat it as explicit deploy confirmation.
2. Use `scripts/deploy.ps1` (REST API) as the primary deployment path.
3. Use MCP `update_workflow` only as fallback when the REST API is unavailable or the API key is invalid.
4. Identify the remote workflow by canonical name and update it in place.
5. Exclude read-only fields from the request body.
6. Verify the remote workflow after deploy.
7. Do not activate or deactivate the workflow unless the user asked for that specifically.

## Credential Portability Rule

n8n credential IDs are instance-specific.

In repository-tracked workflow JSON:
- leave credential `id` as an empty string `""`
- keep the credential `name`

During deploy:
- resolve the actual credential ID from the target n8n instance
- inject it only into the deploy payload
- never write the resolved ID back to the repository

## Workflow Handling Conventions

When creating a new workflow:
1. Understand the automation goal.
2. Resolve new node types through MCP.
3. Save the draft in `workflows/draft/`.
4. Validate and inspect through MCP when useful.
5. Deploy via `scripts/deploy.ps1` after user confirmation; use MCP `update_workflow` only as fallback.
6. Move or copy the selected version to `workflows/active/` only when it becomes the active source of truth.

When modifying an existing workflow:
1. Back up the active file first.
2. Edit the workflow JSON locally.
3. Resolve any new node types via MCP before writing them.
4. Deploy via `scripts/deploy.ps1`; use MCP `update_workflow` only as fallback when REST is unavailable.
5. Keep the local active JSON aligned with the intended deployed state.

When pulling workflows from the server:
1. Save each pulled workflow under `workflows/active/`.
2. Preserve repository naming conventions.
3. Treat the pull as a snapshot activity for Git history.

## Implementation Focus

Use `AGENTS/IMPLEMENTATION_TRACK.md` as the source of truth for:
- feature status
- milestone order
- what is already done
- the next suggested implementation step
