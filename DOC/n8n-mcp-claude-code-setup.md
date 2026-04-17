# Configurazione MCP Server n8n con Claude Code in VSCode

## Panoramica

Questo documento descrive come abilitare il server MCP integrato di n8n e configurarlo per l'uso con Claude Code in Visual Studio Code. Una volta configurato, Claude Code può leggere, creare, modificare, testare ed eseguire workflow n8n direttamente dalla chat, senza aprire l'interfaccia web.

---

## Concetti chiave

### Due ruoli distinti dell'MCP in n8n

| Ruolo | Descrizione |
|---|---|
| **n8n come MCP server** | n8n espone i propri workflow come strumenti per AI client esterni (Claude Desktop, Lovable, ecc.) |
| **Claude Code gestisce n8n via MCP** | Claude Code si connette all'endpoint MCP di n8n per leggere/creare/modificare workflow (quello che usiamo in questo progetto) |

Questo documento riguarda il **secondo ruolo**.

### Toggle "Available in MCP" (UI di n8n)

Il toggle visibile nella pagina *Instance-level MCP* di n8n (e nei dettagli di ogni workflow) **non è necessario** per gestire i workflow da Claude Code. Serve solo per esporre un workflow come tool eseguibile da client AI esterni che usano n8n come server MCP.

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

### 3. Creare il file `.mcp.json` nel progetto

Nella root del progetto crea il file `.mcp.json` con questa struttura:

```json
{
  "mcpServers": {
    "n8n-mcp": {
      "type": "http",
      "url": "https://<tuo-dominio-n8n>/mcp-server/http",
      "headers": {
        "Authorization": "Bearer <token-jwt-generato-al-passo-2>"
      }
    }
  }
}
```

Sostituisci:
- `<tuo-dominio-n8n>` con il dominio o IP del tuo server n8n (es. `n8n.example.com`)
- `<token-jwt-generato-al-passo-2>` con il token copiato al passo precedente

### 4. Aggiungere `.mcp.json` al `.gitignore`

Il file `.mcp.json` contiene un token segreto e **non deve mai essere committato** su Git. Verifica che il `.gitignore` contenga la riga:

```
.mcp.json
```

### 5. Verificare la connessione da Claude Code in VSCode

1. Apri il progetto in VSCode con l'estensione Claude Code attiva.
2. Avvia una sessione Claude Code.
3. Chiedi a Claude di cercare i workflow esistenti. Se la connessione funziona, riceverai l'elenco dei workflow presenti sul server n8n.

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
| JWT Bearer (`.mcp.json`) | File `.mcp.json` (non committato) | MCP endpoint `/mcp-server/http` | Connessione Claude Code ↔ n8n |

Le due credenziali non interferiscono tra loro.

---

## Note di sicurezza

- **Non committare mai `.mcp.json`** su Git — contiene il token JWT.
- **Non committare mai `.env`** — contiene `WSPAF_N8N_API_KEY`.
- Entrambi i file sono già esclusi dal `.gitignore` del progetto.
- Se il token MCP viene compromesso, rigeneralo dalla pagina *Settings → MCP* di n8n e aggiorna il `.mcp.json` localmente.

---

## Riferimenti

- Documentazione n8n MCP: [docs.n8n.io](https://docs.n8n.io)
- Claude Code MCP: configurazione tramite `.mcp.json` nella root del progetto
