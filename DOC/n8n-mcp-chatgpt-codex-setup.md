# n8n MCP Server Setup with Codex

## Overview

This document describes how to enable n8n's built-in MCP server and configure it for use with Codex. Once configured, Codex can interact with the MCP tools exposed by n8n directly from the session, without opening the web interface for every operation.

---

## Key concepts

### Two distinct roles of MCP in n8n

| Role | Description |
|---|---|
| **n8n as an MCP server** | n8n exposes its workflows as tools for external AI clients (Codex, Claude, Lovable, etc.) |
| **Codex manages n8n via MCP** | Codex connects to n8n's MCP endpoint to read/create/modify workflows (what we use in this project) |

This document is about the **second role**.

### "Available in MCP" toggle (n8n UI)

The toggle visible on n8n's *Instance-level MCP* page (and in each workflow's details) **is used when you want to expose a workflow to MCP clients**, including Codex when it needs to see or use that workflow through n8n's Instance-level MCP.

According to the current n8n documentation:
- the workflow must be published
- it must have a supported trigger
- it must be explicitly made available in MCP

In the context of this project, this toggle is mainly relevant for workflows that you want to make visible or invokable via MCP on the n8n server.

---

## Setup steps

### 1. Enable Instance-level MCP on n8n

1. Go to **Settings → MCP** (or search for "Instance-level MCP" in the Settings menu).
2. Enable the feature.
3. Generate or copy an **MCP Access Token** from the MCP connection screen. This token is specific to the MCP endpoint and separate from the REST API key.
4. Copy the generated token — it will be used in the next step.

> Treat it as a bearer token for the MCP endpoint. Do not rely on internal details of the token format as part of the configuration.

### 2. Choose the correct configuration file

For this project, Codex reads MCP servers from the user file of the environment where it is actually running. The configuration does not belong in the repository.

| Where Codex runs | File to use |
|---|---|
| **WSL/Linux** | `~/.codex/config.toml` |
| **Windows native** | `C:\Users\<user>\.codex\config.toml` |

Rule of thumb:
- if you open VS Code in WSL mode, use the WSL home directory
- if you use Codex on the Windows side, use the Windows user home

### 3. Add the n8n MCP server

In the `config.toml` of the chosen environment, add a section like one of the following.

**Configuration documented by n8n for Codex CLI:**

```toml
[mcp_servers.n8n_mcp]
url = "https://<your-n8n-domain>/mcp-server/http"
http_headers = { "authorization" = "Bearer <jwt-token-generated-in-step-2>" }
```

> **Syntax warning:** use `http_headers` (not `headers`), prefer the server name `n8n_mcp`, and do not add `type = "http"` — Codex infers it from the URL.

If you prefer not to place the token in clear text in the local file, you can consider an environment-variable-based variant only if the Codex client you are using explicitly supports it in your version. The configuration above is the one confirmed in the n8n documentation for Codex CLI.

A ready-to-use template is available in [DOC/config.example.toml](./config.example.toml).

### 4. Verify that the project is trusted

In the `config.toml` of the current environment, also add this project as trusted.

- If Codex runs in **WSL/Linux**, use the `/mnt/c/...` path.
- If Codex runs in **Windows native**, use the `C:\...` path.
- If you open the same repo from different paths, you can mark more than one path as trusted.

In the context of this project, when Codex runs in WSL, a working configuration is for example:

```toml
[projects."/mnt/c/spaziodati/googledrivelavoro/progetti/pr-automazioni con n8n/wp-social-publisher-with-n8n"]
trust_level = "trusted"
```

To avoid errors, use exactly the value of `cwd` or the output of `pwd` from the current Codex session.

### 5. Restart Codex and verify the connection

1. Restart Codex or reload the session.
2. Ask Codex to search for existing workflows. If the connection works, you will receive the list of workflows available on the n8n server.

If you edit `config.toml` while Codex is already open, the new MCP server usually is not loaded into the current session: a new session or extension/app restart is required.

### 6. Note on the project's REST API

This project also uses n8n's Public REST API for local deploy and verification scripts, through `WSPAF_N8N_API_KEY`. This API key is separate from the MCP token and is not needed to configure Codex via MCP.

---

## What you can do with the configured MCP server

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

## Credentials involved: no conflict

The project uses two separate credentials for different purposes:

| Credential | Where it is configured | Target endpoint | Purpose |
|---|---|---|---|
| `WSPAF_N8N_API_KEY` | Local environment variable of the machine/session | REST API `/api/v1/...` | Deploy scripts, manual REST calls |
| JWT Bearer (`config.toml`) | Local user file of the current environment | MCP endpoint `/mcp-server/http` | Codex ↔ n8n connection |

The two credentials do not interfere with each other.

---

## Security notes

- **Never commit your user `config.toml`** with the JWT token — it is a local file of the current environment.
- **Never commit local files containing REST or MCP credentials** — the project uses local environment variables and user files such as `config.toml`.
- **Never commit real tokens in template files under `DOC/`** — use placeholders only.
- **Do not copy the real content of `http_headers.authorization`** from your user file into project documents.
- If the MCP token is compromised, regenerate it from the n8n *Settings → MCP* page and update the local file of the environment in use.

---

## References

- n8n MCP documentation: [docs.n8n.io](https://docs.n8n.io)
- MCP docs for Codex/OpenAI: [developers.openai.com/learn/docs-mcp](https://developers.openai.com/learn/docs-mcp)
- n8n guide for connecting Codex CLI: [docs.n8n.io/advanced-ai/accessing-n8n-mcp-server/](https://docs.n8n.io/advanced-ai/accessing-n8n-mcp-server/)
- OpenAI overview of Codex: [help.openai.com/en/articles/11369540-codex-in-chatgpt](https://help.openai.com/en/articles/11369540-codex-in-chatgpt)
