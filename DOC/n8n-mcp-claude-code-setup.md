# Configurazione MCP Server n8n con Claude Code in VSCode

## Panoramica

Questo documento descrive come configurare il server MCP di n8n per l'uso con Claude Code in VSCode, nel contesto del progetto **WP Social Publisher Approval Flow**. Una volta configurato, Claude Code può leggere, creare, modificare, testare ed eseguire workflow n8n direttamente dalla chat, senza aprire l'interfaccia web di n8n.

Il server n8n di questo progetto è raggiungibile su `n8n.claudiobattaglino.it`.

---

## Concetto chiave: due ruoli dell'MCP in n8n

n8n può usare MCP in due modi distinti:

| Ruolo | Descrizione |
|---|---|
| **n8n come MCP server** | n8n espone i propri workflow come tool per AI client esterni |
| **Claude Code gestisce n8n via MCP** | Claude Code si connette all'endpoint MCP di n8n per gestire i workflow |

Questo documento riguarda il **secondo ruolo**. Il toggle "Available in MCP" visibile nella UI di n8n non è necessario per questo scopo: serve solo per esporre workflow come tool eseguibili da client AI esterni.

---

## Passi di configurazione

### 1. Abilitare la Public API di n8n

1. Accedi all'interfaccia web di n8n → **Settings → API**.
2. Abilita la Public API e genera una API key.

Questa chiave corrisponde alla variabile `WSPAF_N8N_API_KEY` usata dagli script REST locali — è distinta dal token MCP.

### 2. Abilitare l'Instance-level MCP e generare il token

1. Vai in **Settings → MCP**.
2. Attiva la funzionalità.
3. Genera un **MCP API token** (formato JWT con `"aud": "mcp-server-api"`).
4. Copia il token — servirà nel passo successivo.

### 3. Configurare il server MCP in Claude Code

Ci sono tre modalità alternative: sceglierne una è sufficiente, non è necessario combinarle.

| Scope | Metodo | Disponibile in |
|---|---|---|
| **Progetto** | File `.mcp.json` nella root del repository | Solo quel progetto |
| **Locale** | `.claude/settings.local.json` nella root del progetto | Solo quel progetto, non versionato |
| **Utente (globale)** | Comando CLI `claude mcp add --scope user` | Tutti i progetti |

**Opzione A — Progetto (`.mcp.json`):**

```json
{
  "mcpServers": {
    "n8n-mcp": {
      "type": "http",
      "url": "https://n8n.claudiobattaglino.it/mcp-server/http",
      "headers": {
        "Authorization": "Bearer <token-jwt-dal-passo-2>"
      }
    }
  }
}
```

Il file `.mcp.json` è già escluso dal `.gitignore` di questo progetto — non va mai committato.

**Opzione B — Utente globale (valido per tutti i progetti):**

Esegui questo comando dal terminale, **fuori da una sessione Claude Code attiva**. Il comando va eseguito una sola volta e persiste dopo il riavvio di VSCode.

```powershell
claude mcp add --scope user n8n-mcp --transport http "https://n8n.claudiobattaglino.it/mcp-server/http" --header "Authorization: Bearer <token-jwt-dal-passo-2>"
```

> Note sulla configurazione utente:
> - `C:\Users\<utente>\.claude\settings.json` **non supporta** il campo `mcpServers`.
> - `C:\Users\<utente>\.claude.json` contiene le credenziali di autenticazione Claude, non la config MCP.
> - Il file `.mcp.json` **non viene letto** dalla home di Windows: funziona solo nella root del progetto.

### 4. Verificare la connessione

1. Apri il progetto in VSCode con l'estensione Claude Code attiva.
2. Avvia una sessione Claude Code.
3. Chiedi a Claude di cercare i workflow esistenti — se la connessione funziona, riceverai l'elenco dei workflow presenti su n8n.

---

## Operazioni disponibili con il server MCP configurato

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

## Credenziali del progetto

Il progetto usa due credenziali distinte che non interferiscono tra loro:

| Credenziale | Dove si configura | Scopo |
|---|---|---|
| `WSPAF_N8N_API_KEY` | Variabile d'ambiente locale (`.env`) | Script di deploy e chiamate REST |
| JWT Bearer MCP | `.mcp.json` o config utente Claude Code | Connessione Claude Code ↔ n8n |

Entrambi i file che contengono questi valori (`.env` e `.mcp.json`) sono esclusi dal `.gitignore`. Se il token MCP viene compromesso, rigeneralo da **Settings → MCP** su n8n e aggiorna la configurazione locale.
