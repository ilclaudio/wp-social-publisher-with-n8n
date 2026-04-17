# Configurazione MCP Server n8n con ChatGPT Codex

## Panoramica

Questo documento descrive come abilitare il server MCP integrato di n8n e configurarlo per l'uso con ChatGPT Codex. Una volta configurato, Codex può leggere, creare, modificare, testare ed eseguire workflow n8n direttamente dalla chat, senza aprire l'interfaccia web.

---

## Concetti chiave

### Due ruoli distinti dell'MCP in n8n

| Ruolo | Descrizione |
|---|---|
| **n8n come MCP server** | n8n espone i propri workflow come strumenti per AI client esterni (Codex, Claude, Lovable, ecc.) |
| **Codex gestisce n8n via MCP** | Codex si connette all'endpoint MCP di n8n per leggere/creare/modificare workflow (quello che usiamo in questo progetto) |

Questo documento riguarda il **secondo ruolo**.

### Toggle "Available in MCP" (UI di n8n)

Il toggle visibile nella pagina *Instance-level MCP* di n8n (e nei dettagli di ogni workflow) **non è necessario** per gestire i workflow da Codex. Serve solo per esporre un workflow come tool eseguibile da client AI esterni che usano n8n come server MCP.

---

## Passi di configurazione

### 1. Abilitare la Public API di n8n

1. Accedi all'interfaccia web di n8n.
2. Vai in **Settings → API**.
3. Abilita la Public API e genera una API key (questa è la `WSPAF_N8N_API_KEY` usata per gli script REST locali — non quella MCP).

### 2. Abilitare l'Instance-level MCP su n8n

1. Vai in **Settings → MCP** (o cerca "Instance-level MCP" nel menu Settings).
2. Attiva la funzionalità.
3. Genera un **MCP API token** (JWT). Questo token è specifico per l'endpoint MCP e distinto dalla API key REST.
4. Copia il token generato — verrà usato nel passo successivo.

> Il token ha formato JWT con `"aud": "mcp-server-api"` e `"iss": "n8n"`.

### 3. Configurare Codex con il token MCP

La configurazione MCP di Codex va nel file utente `~/.codex/config.toml`. Per questo progetto il file è in:

```
C:\Users\<utente>\.codex\config.toml
```

Aggiungi la seguente sezione (scegli una delle due opzioni):

**Opzione A — token via variabile d'ambiente (consigliata):**

```toml
[mcp_servers.n8n-mcp]
url = "https://n8n.claudiobattaglino.it/mcp-server/http"
bearer_token_env_var = "N8N_MCP_TOKEN"
```

Richiede di impostare `N8N_MCP_TOKEN=<token-jwt>` nelle variabili d'ambiente utente di Windows.

**Opzione B — header statico nel config (accettabile, file non committato):**

```toml
[mcp_servers.n8n-mcp]
url = "https://n8n.claudiobattaglino.it/mcp-server/http"

[mcp_servers.n8n-mcp.http_headers]
Authorization = "Bearer <token-jwt-generato-al-passo-2>"
```

> **Attenzione alla sintassi:** usa `http_headers` (non `headers`) e non aggiungere `type = "http"` — Codex lo inferisce dall'URL.

Un template pronto è disponibile in [DOC/codex-mcp-config.example.toml](./codex-mcp-config.example.toml).

### 4. Verificare che il progetto sia trusted

Il file `~/.codex/config.toml` deve contenere questo progetto come trusted, altrimenti Codex non legge la configurazione MCP:

```toml
[projects.'C:\SPAZIODATI\GoogleDriveLavoro\Progetti\PR-Automazioni con n8n\wp-social-publisher-with-n8n']
trust_level = "trusted"
```

### 5. Riavviare Codex e verificare la connessione

1. Riavvia Codex o ricarica la sessione.
2. Chiedi a Codex di cercare i workflow esistenti. Se la connessione funziona, riceverai l'elenco dei workflow presenti sul server n8n.

---

## Cosa puoi fare con il server MCP configurato

| Operazione | Tool MCP |
|---|---|
| Cercare/elencare workflow | `search_workflows` |
| Leggere il dettaglio di un workflow | `get_workflow_details` |
| Creare un nuovo workflow da codice SDK | `create_workflow_from_code` |
| Aggiornare un workflow esistente | `update_workflow` |
| Archiviare un workflow | `archive_workflow` |
| Attivare / disattivare un workflow | `publish_workflow` / `unpublish_workflow` |
| Eseguire un workflow | `execute_workflow` |
| Testare un workflow | `test_workflow` |
| Leggere il risultato di un'esecuzione | `get_execution` |
| Validare il codice prima del deploy | `validate_workflow` |
| Cercare nodi disponibili su n8n | `search_nodes` |
| Ottenere le definizioni TypeScript dei nodi | `get_node_types` |
| Leggere la documentazione dell'SDK n8n | `get_sdk_reference` |

---

## Credenziali in gioco: nessun conflitto

Il progetto usa due credenziali distinte per scopi diversi:

| Credenziale | Dove si configura | Endpoint target | Scopo |
|---|---|---|---|
| `WSPAF_N8N_API_KEY` | Variabile d'ambiente locale (`.env`) | REST API `/api/v1/...` | Script di deploy, chiamate REST manuali |
| JWT Bearer (`~/.codex/config.toml`) | File locale utente (non committato) | MCP endpoint `/mcp-server/http` | Connessione Codex ↔ n8n |

Le due credenziali non interferiscono tra loro.

---

## Note di sicurezza

- **Non committare mai `~/.codex/config.toml`** con il token JWT — è un file utente locale.
- **Non committare mai `.env`** — contiene `WSPAF_N8N_API_KEY`.
- Se il token MCP viene compromesso, rigeneralo dalla pagina *Settings → MCP* di n8n e aggiorna `config.toml` localmente.

---

## Riferimenti

- Documentazione n8n MCP: [docs.n8n.io](https://docs.n8n.io)
- Documentazione Codex MCP: [developers.openai.com/codex/mcp](https://developers.openai.com/codex/mcp)
