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

### 1. Abilitare l'Instance-level MCP su n8n

1. Vai in **Settings → MCP** (o cerca "Instance-level MCP" nel menu Settings).
2. Attiva la funzionalità.
3. Genera un **MCP API token** (JWT). Questo token è specifico per l'endpoint MCP e distinto dalla API key REST.
4. Copia il token generato — verrà usato nel passo successivo.

> Il token ha formato JWT con `"aud": "mcp-server-api"` e `"iss": "n8n"`.

### 2. Scegliere il file di configurazione corretto

Per questo progetto, Codex legge i server MCP dal file utente dell'ambiente in cui sta realmente girando. La configurazione non va nel repository.

| Dove gira Codex | File da usare |
|---|---|
| **WSL/Linux** | `~/.codex/config.toml` |
| **Windows nativo** | `C:\Users\<utente>\.codex\config.toml` |

Regola pratica:
- se apri VS Code in modalita WSL, usa la home di WSL
- se usi Codex lato Windows, usa la home utente di Windows

### 3. Aggiungere il server MCP di n8n

Nel `config.toml` dell'ambiente scelto aggiungi una sezione come una delle seguenti.

**Opzione A — token via variabile d'ambiente (consigliata):**

```toml
[mcp_servers.n8n_mcp]
url = "https://<tuo-dominio-n8n>/mcp-server/http"
bearer_token_env_var = "N8N_MCP_TOKEN"
```

Imposta `N8N_MCP_TOKEN` nello stesso ambiente in cui gira Codex:
- in WSL, come variabile dell'ambiente Linux/WSL
- in Windows nativo, come variabile utente di Windows

**Opzione B — header statico nel config (accettabile, file non committato):**

```toml
[mcp_servers.n8n_mcp]
url = "https://<tuo-dominio-n8n>/mcp-server/http"
http_headers = { "authorization" = "Bearer <token-jwt-generato-al-passo-2>" }
```

> **Attenzione alla sintassi:** usa `http_headers` (non `headers`), preferisci il nome server `n8n_mcp`, e non aggiungere `type = "http"` — Codex lo inferisce dall'URL.

Un template pronto è disponibile in [DOC/config.example.toml](./config.example.toml).

### 4. Verificare che il progetto sia trusted

Nel `config.toml` dell'ambiente corrente aggiungi anche questo progetto come trusted.

- Se Codex gira in **WSL/Linux**, usa il path `/mnt/c/...`.
- Se Codex gira in **Windows nativo**, usa il path `C:\...`.
- Se apri lo stesso repo da percorsi diversi, puoi marcare come trusted piu di un path.

Nel contesto di questo progetto, quando Codex gira in WSL, una configurazione funzionante e per esempio:

```toml
[projects."/mnt/c/spaziodati/googledrivelavoro/progetti/pr-automazioni con n8n/wp-social-publisher-with-n8n"]
trust_level = "trusted"
```

Per evitare errori, usa esattamente il valore di `cwd` o l'output di `pwd` della sessione Codex corrente.

### 5. Riavviare Codex e verificare la connessione

1. Riavvia Codex o ricarica la sessione.
2. Chiedi a Codex di cercare i workflow esistenti. Se la connessione funziona, riceverai l'elenco dei workflow presenti sul server n8n.

Se modifichi `config.toml` mentre Codex e gia aperto, il nuovo server MCP in genere non viene caricato nella sessione corrente: serve una nuova sessione o un riavvio dell'estensione/app.

### 6. Nota sulla REST API del progetto

Questo progetto usa anche la Public API REST di n8n per script locali di deploy e verifica, tramite `WSPAF_N8N_API_KEY`. Questa API key e separata dal token MCP e non serve per configurare Codex via MCP.

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
| JWT Bearer (`config.toml`) | File locale utente dell'ambiente corrente | MCP endpoint `/mcp-server/http` | Connessione Codex ↔ n8n |

Le due credenziali non interferiscono tra loro.

---

## Note di sicurezza

- **Non committare mai il tuo `config.toml` utente** con il token JWT — è un file locale dell'ambiente corrente.
- **Non committare mai `.env`** — contiene `WSPAF_N8N_API_KEY`.
- **Non committare mai token reali nei file template in `DOC/`** — usa solo placeholder.
- **Non copiare nei documenti di progetto il contenuto reale di `http_headers.authorization`** dal tuo file utente.
- Se il token MCP viene compromesso, rigeneralo dalla pagina *Settings → MCP* di n8n e aggiorna il file locale dell'ambiente in uso.

---

## Riferimenti

- Documentazione n8n MCP: [docs.n8n.io](https://docs.n8n.io)
- Docs MCP per Codex/OpenAI: [developers.openai.com/learn/docs-mcp](https://developers.openai.com/learn/docs-mcp)
