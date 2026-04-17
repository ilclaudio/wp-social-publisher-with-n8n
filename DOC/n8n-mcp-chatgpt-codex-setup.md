# Configurazione MCP Server n8n con ChatGPT Codex

## Obiettivo

Abilitare il server MCP di n8n anche in **ChatGPT Codex**, riusando la stessa istanza MCP già configurata per Claude Code, ma con la configurazione locale corretta per Codex.

Questo documento elenca i passaggi da fare e quelli che faremo in questo progetto per rendere il server MCP disponibile in Codex senza committare segreti nel repository.

---

## Stato attuale del progetto

- Il server MCP di n8n è abilitato e raggiungibile.
- Per Codex, la config operativa va nel file utente [`~/.codex/config.toml`](https://developers.openai.com/learn/docs-mcp).
- Il token JWT MCP **non va committato** nel repository.

---

## Cosa serve

1. Un endpoint MCP di n8n attivo.
2. Un token MCP JWT generato da n8n.
3. Una configurazione locale di Codex che registri il server `n8n-mcp`.
4. Un progetto aperto in Codex dalla root di questo repository.

---

## Passi da fare

### 1. Verificare che n8n MCP sia attivo

1. Accedi alla UI di n8n.
2. Vai in `Settings → MCP`.
3. Verifica che l'Instance-level MCP sia abilitato.
4. Verifica che il token JWT MCP sia valido.
5. Verifica l'URL dell'endpoint MCP, ad esempio:

```text
https://n8n.claudiobattaglino.it/mcp-server/http
```

---

### 2. Tenere il token fuori dal repository

1. Mantieni il token MCP solo in configurazione locale.
2. Non committare `.mcp.json`.
3. Verifica che `.gitignore` escluda `.mcp.json`.

Questo progetto può lasciare la config MCP locale nel file `.mcp.json`, ma il file deve restare fuori da Git.

---

### 3. Configurare Codex localmente

Codex deve conoscere il server MCP `n8n-mcp` tramite la sua configurazione utente.

Percorso corretto:

```text
~/.codex/config.toml
```

Passi pratici:

1. Apri `~/.codex/config.toml`.
2. Aggiungi un server MCP HTTP con nome `n8n-mcp`.
3. Imposta l'URL dell'endpoint MCP di n8n.
4. Aggiungi l'header `Authorization: Bearer <token-jwt>`.
5. Salva la configurazione.
6. Riavvia Codex o ricarica la sessione.

Esempio concettuale:

```toml
# Esempio indicativo: adattare alla sintassi supportata dalla tua installazione Codex
[mcp_servers.n8n-mcp]
type = "http"
url = "https://n8n.claudiobattaglino.it/mcp-server/http"

[mcp_servers.n8n-mcp.headers]
Authorization = "Bearer <token-jwt>"
```

> Nota: il formato esatto dipende dalla build/installazione di Codex in uso. Il principio resta lo stesso: registrare il server MCP nella config utente del client, non nel repository.

Un template pronto da copiare è disponibile in [DOC/codex-mcp-config.example.toml](./codex-mcp-config.example.toml).

---

### 4. Aprire il progetto in Codex

1. Apri questa repository come workspace di Codex.
2. Verifica che Codex stia leggendo `~/.codex/config.toml`.
3. Controlla che il server `n8n-mcp` risulti disponibile.

Se il server non compare:

1. verifica che il token sia corretto;
2. verifica che l'endpoint risponda;
3. verifica che la configurazione locale di Codex sia nel file giusto;
4. riavvia Codex.

---

### 5. Verificare il funzionamento

Una volta attivo:

1. Chiedi a Codex di elencare i workflow n8n.
2. Chiedi di leggere un workflow esistente.
3. Chiedi di cercare i node type già presenti.
4. Se la risposta arriva, il server MCP è correttamente attivo.

---

## Attività che faremo in questo progetto

1. Tenere il file MCP locale fuori dal version control.
2. Lasciare documentato il setup per Codex nel presente file.
3. Usare Codex per leggere, analizzare e modificare i workflow n8n via MCP quando il server è disponibile.
4. Verificare i workflow prima di qualsiasi deploy server-side.

---

## Checklist operativa

- [x] n8n MCP abilitato su server
- [x] token JWT MCP generato
- [x] token JWT conservato solo localmente (non committato)
- [x] `.mcp.json` escluso da Git
- [ ] server `n8n-mcp` registrato in `~/.codex/config.toml`
- [ ] Codex riavviato o ricaricato
- [ ] test di lettura workflow riuscito
- [ ] test di ricerca node type riuscito

---

## Note di sicurezza

- Non inserire segreti nei workflow JSON.
- Non committare token JWT, API key o `.env`.
- Se il token MCP cambia, rigeneralo su n8n e aggiorna la config locale.
