# n8n MCP Server Setup with Claude Code in VSCode

## Overview

This document describes how to configure n8n's MCP server for use with Claude Code in VSCode, in the context of the **WP Social Publisher Approval Flow** project. Once configured, Claude Code can read, create, modify, test, and execute n8n workflows directly from the chat, without opening the n8n web interface.

The n8n server for this project is reachable at `n8n.miosito.org`.

---

## Key concept: two roles of MCP in n8n

n8n can use MCP in two distinct ways:

| Role | Description |
|---|---|
| **n8n as an MCP server** | n8n exposes its workflows as tools for external AI clients |
| **Claude Code manages n8n via MCP** | Claude Code connects to n8n's MCP endpoint to manage workflows |

This document is about the **second role**. The "Available in MCP" toggle visible in the n8n UI is not required for this purpose: it is only used to expose workflows as executable tools for external AI clients.

---

## Setup steps

### 1. Enable the n8n Public API

1. Open the n8n web interface → **Settings → API**.
2. Enable the Public API and generate an API key.

This key corresponds to the `WSPAF_N8N_API_KEY` variable used by local REST scripts — it is separate from the MCP token.

### 2. Enable Instance-level MCP and generate the token

1. Go to **Settings → MCP**.
2. Enable the feature.
3. Generate an **MCP API token** (JWT format with `"aud": "mcp-server-api"`).
4. Copy the token — it will be needed in the next step.

### 3. Configure the MCP server in Claude Code

There are two alternative modes: choosing one is enough, there is no need to combine them.

| Scope | Method | Available in |
|---|---|---|
| **Project** | `.mcp.json` file in the repository root | Only that project |
| **User (global)** | CLI command `claude mcp add --scope user` (saved in `~/.claude.json`) | All projects |

**Option A — Project (`.mcp.json`):**

```json
{
  "mcpServers": {
    "n8n-mcp": {
      "type": "http",
      "url": "https://n8n.miosito.org/mcp-server/http",
      "headers": {
        "Authorization": "Bearer <jwt-token-from-step-2>"
      }
    }
  }
}
```

The `.mcp.json` file is already excluded by this project's `.gitignore` — it must never be committed.

**Option B — Global user config (valid for all projects):**

Run this command from the terminal, **outside an active Claude Code session**. The command only needs to be run once and persists after restarting VSCode.

```powershell
claude mcp add --scope user n8n-mcp --transport http "https://n8n.miosito.org/mcp-server/http" --header "Authorization: Bearer <jwt-token-from-step-2>"
```

> Notes on user configuration:
> - `C:\Users\<user>\.claude\settings.json` **does not support** the `mcpServers` field.
> - `C:\Users\<user>\.claude.json` contains MCP config at local and user scope (it is not only for authentication credentials).
> - The `.mcp.json` file **is not read** from the Windows home directory: it works only in the project root.

### 4. Verify the connection

1. Open the project in VSCode with the Claude Code extension enabled.
2. Start a Claude Code session.
3. Ask Claude to search existing workflows — if the connection works, you will receive the list of workflows available in n8n.

---

## Operations available with the configured MCP server

| Operation | MCP tool |
|---|---|
| Search/list workflows | `search_workflows` |
| Read workflow details | `get_workflow_details` |
| Create a new workflow from SDK code | `create_workflow_from_code` |
| Update an existing workflow | `update_workflow` |
| Archive a workflow | `archive_workflow` |
| Activate / deactivate a workflow | `publish_workflow` / `unpublish_workflow` |
| Execute a workflow | `execute_workflow` |
| Test a workflow | `test_workflow` |
| Read the result of an execution | `get_execution` |
| Validate code before deploy | `validate_workflow` |
| Search available nodes in n8n | `search_nodes` |
| Get TypeScript definitions for nodes | `get_node_types` |
| Read the n8n SDK documentation | `get_sdk_reference` |

---

## Project credentials

The project uses two distinct credentials that do not interfere with each other:

| Credential | Where it is configured | Purpose |
|---|---|---|
| `WSPAF_N8N_API_KEY` | Machine-level environment variable (`setx ... /M`) | Deploy scripts and REST calls |
| MCP JWT Bearer | `.mcp.json` or Claude Code user config | Claude Code ↔ n8n connection |

Both files containing these values (`.env` and `.mcp.json`) are excluded by `.gitignore`. If the MCP token is compromised, regenerate it from **Settings → MCP** in n8n and update the local configuration.
