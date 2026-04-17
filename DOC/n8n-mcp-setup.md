# Installazione di czlonkowski/n8n-mcp su VSCode + Claude Code (Windows 11)

`czlonkowski/n8n-mcp` è un server MCP che permette a Claude Code di consultare la documentazione e i parametri dei nodi n8n direttamente durante lo sviluppo, senza dover indovinare i nomi dei tipi nodo o la struttura dei parametri.

---

## Prerequisiti

1. **Installa Node.js** (versione 18 o superiore) da [nodejs.org](https://nodejs.org).
   - Scegli la versione LTS.
   - Durante l'installazione, assicurati che l'opzione "Add to PATH" sia selezionata.

2. **Verifica l'installazione** aprendo un terminale (PowerShell o Prompt dei comandi) e digitando:
   ```
   node --version
   npx --version
   ```
   Entrambi devono restituire un numero di versione senza errori.

3. **Installa Claude Code** seguendo le istruzioni ufficiali su [claude.ai/code](https://claude.ai/code).

4. **Installa l'estensione Claude Code per VSCode** dal marketplace di VSCode (cerca "Claude Code").

---

## Configurazione del server MCP

### Opzione A — Solo per questo progetto (consigliata)

5. **Crea il file `.mcp.json`** nella root del progetto con il seguente contenuto:
   ```json
   {
     "mcpServers": {
       "n8n": {
         "command": "npx",
         "args": ["-y", "@czlonkowski/n8n-mcp"],
         "env": {
           "N8N_API_URL": "https://<indirizzo-del-tuo-server-n8n>",
           "N8N_API_KEY": "<la-tua-api-key-n8n>"
         }
       }
     }
   }
   ```
   Sostituisci `N8N_API_URL` e `N8N_API_KEY` con i valori reali del tuo server n8n.

6. **Verifica che `.mcp.json` sia nel `.gitignore`** per non committare la chiave API:
   ```
   .mcp.json
   ```
   Se non c'è, aggiungilo manualmente al file `.gitignore` del progetto.

### Opzione B — Per tutti i progetti (globale)

5. **Crea il file `%USERPROFILE%\.claude\mcp.json`** (es. `C:\Users\claudio\.claude\mcp.json`) con lo stesso contenuto JSON riportato nell'Opzione A.
   - Con questa opzione il file non è nel repo, quindi non serve `.gitignore`.

---

## Come ottenere la n8n API Key

7. Accedi al tuo server n8n via browser.

8. Vai su **Settings → API** nel menu laterale.

9. Crea o copia la chiave API esistente.

10. Verifica che le API pubbliche siano abilitate (toggle "Enable Public API" deve essere attivo).

---

## Attivazione in Claude Code

11. **Riavvia VSCode** (o riavvia la sessione Claude Code con `/exit` e riapertura).

12. Claude Code carica automaticamente i server MCP configurati all'avvio. Al primo utilizzo, `npx` scarica il pacchetto `@czlonkowski/n8n-mcp` — richiede connessione internet.

13. **Verifica che il server sia attivo**: all'inizio di una sessione, i tool MCP disponibili vengono elencati. Dovresti vedere tool come `search_nodes`, `get_node_info`, `get_node_documentation`.

---

## Utilizzo

Una volta attivo, Claude Code può:

- Cercare nodi per nome o funzione: `search_nodes("openai")`
- Ottenere parametri esatti di un nodo: `get_node_info("@n8n/n8n-nodes-langchain.openAi")`
- Consultare la documentazione completa di un nodo prima di implementarlo nel workflow JSON

---

## Note di sicurezza

- Non committare mai `.mcp.json` nel repository — contiene la chiave API n8n.
- La chiave API n8n dà accesso completo in lettura/scrittura ai workflow del server.
- Se la chiave viene compromessa, rigenerala subito da **Settings → API** in n8n.
