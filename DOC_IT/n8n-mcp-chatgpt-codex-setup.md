# Configurazione MCP Server n8n con Codex

## Panoramica

Questo documento descrive come abilitare il server MCP integrato di n8n e configurarlo per l'uso con Codex. Una volta configurato, Codex può interagire con gli strumenti MCP esposti da n8n direttamente dalla sessione, senza aprire l'interfaccia web per ogni operazione.

---

## Concetti chiave

### Due ruoli distinti dell'MCP in n8n

| Ruolo | Descrizione |
|---|---|
| **n8n come MCP server** | n8n espone i propri workflow come strumenti per AI client esterni (Codex, Claude, Lovable, ecc.) |
| **Codex gestisce n8n via MCP** | Codex si connette all'endpoint MCP di n8n per leggere/creare/modificare workflow (quello che usiamo in questo progetto) |

Questo documento riguarda il **secondo ruolo**.

### Toggle "Available in MCP" (UI di n8n)

Il toggle visibile nella pagina *Instance-level MCP* di n8n (e nei dettagli di ogni workflow) **serve quando vuoi esporre un workflow ai client MCP**, incluso Codex quando deve vedere o usare quel workflow tramite l'Instance-level MCP di n8n.

In base alla documentazione n8n attuale:
- il workflow deve essere pubblicato
- deve avere un trigger supportato
- deve essere esplicitamente reso disponibile in MCP

Nel contesto di questo progetto, questo toggle e rilevante soprattutto per i workflow che vuoi rendere visibili o invocabili via MCP sul server n8n.

---

## Passi di configurazione

### 1. Abilitare l'Instance-level MCP su n8n

1. Vai in **Settings → MCP** (o cerca "Instance-level MCP" nel menu Settings).
2. Attiva la funzionalità.
3. Genera o copia un **MCP Access Token** dalla schermata di connessione MCP. Questo token è specifico per l'endpoint MCP e distinto dalla API key REST.
4. Copia il token generato — verrà usato nel passo successivo.

> Trattalo come un bearer token dell'endpoint MCP. Non fare affidamento su dettagli interni del formato del token come parte della configurazione.

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

**Configurazione documentata da n8n per Codex CLI:**

```toml
[mcp_servers.n8n_mcp]
url = "https://<tuo-dominio-n8n>/mcp-server/http"
http_headers = { "authorization" = "Bearer <token-jwt-generato-al-passo-2>" }
```

> **Attenzione alla sintassi:** usa `http_headers` (non `headers`), preferisci il nome server `n8n_mcp`, e non aggiungere `type = "http"` — Codex lo inferisce dall'URL.

Se preferisci non inserire il token in chiaro nel file locale, puoi valutare una variante basata su variabile d'ambiente solo se il client Codex in uso la supporta esplicitamente nella tua versione. La configurazione sopra e quella confermata nella documentazione n8n per Codex CLI.

Un template pronto è disponibile in [config/config.example.toml](../config/config.example.toml).

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
| `WSPAF_N8N_API_KEY` | Variabile d'ambiente locale della macchina/sessione | REST API `/api/v1/...` | Script di deploy, chiamate REST manuali |
| JWT Bearer (`config.toml`) | File locale utente dell'ambiente corrente | MCP endpoint `/mcp-server/http` | Connessione Codex ↔ n8n |

Le due credenziali non interferiscono tra loro.

---

## Note di sicurezza

- **Non committare mai il tuo `config.toml` utente** con il token JWT — è un file locale dell'ambiente corrente.
- **Non committare mai file locali con credenziali REST o MCP** — il progetto usa variabili d'ambiente locali e file utente come `config.toml`.
- **Non committare mai token reali nei file template in `DOC/`** — usa solo placeholder.
- **Non copiare nei documenti di progetto il contenuto reale di `http_headers.authorization`** dal tuo file utente.
- Se il token MCP viene compromesso, rigeneralo dalla pagina *Settings → MCP* di n8n e aggiorna il file locale dell'ambiente in uso.

---

## Riferimenti

- Documentazione n8n MCP: [docs.n8n.io](https://docs.n8n.io)
- Docs MCP per Codex/OpenAI: [developers.openai.com/learn/docs-mcp](https://developers.openai.com/learn/docs-mcp)
- Guida n8n per collegare Codex CLI: [docs.n8n.io/advanced-ai/accessing-n8n-mcp-server/](https://docs.n8n.io/advanced-ai/accessing-n8n-mcp-server/)
- Panoramica OpenAI su Codex: [help.openai.com/en/articles/11369540-codex-in-chatgpt](https://help.openai.com/en/articles/11369540-codex-in-chatgpt)
