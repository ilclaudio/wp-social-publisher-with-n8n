# WP Social Publisher Approval Flow

Automazione che rileva i nuovi articoli pubblicati su WordPress, genera un messaggio social con l'AI, richiede l'approvazione umana via email e pubblica su X (Twitter) solo dopo approvazione esplicita.

## Cosa fa

Quando un nuovo articolo viene pubblicato su un sito WordPress, il workflow:

1. Lo rileva automaticamente (ogni giorno alle 06:00, oppure tramite trigger manuale)
2. Estrae titolo, estratto, URL e immagine in evidenza
3. Genera un breve messaggio social tramite OpenAI (massimo 280 caratteri, hashtag `#n8n`, lingua dell'articolo)
4. Invia un'email di approvazione con i dettagli dell'articolo e il testo generato dall'AI
5. Attende una decisione umana (fino a 24 ore):
   - **Publish** → pubblica il tweet (con immagine, se disponibile)
   - **Do not publish** oppure nessuna risposta → salta la pubblicazione
6. Invia un'email di conferma con l'esito

## Prerequisiti

Prima di configurare questo workflow ti servono:

- Un'istanza **n8n** self-hosted (testata su Ubuntu 22.04)
- Un sito **WordPress** con REST API abilitata
- Un account **OpenAI** con accesso API
- Un server o account **SMTP** per l'invio delle email
- Un account sviluppatore **X (Twitter)** con un'app configurata sia per OAuth1 sia per OAuth2

## Struttura del repository

```
workflows/
  active/     # fonte di verità per il workflow sottoposto a deploy
  draft/      # lavoro in corso
  backup/     # snapshot con timestamp prima di ogni modifica
scripts/
  deploy.ps1  # esegue il deploy del workflow attivo su n8n tramite REST API
AGENTS/       # istruzioni e contesto per gli assistenti AI
DOC/          # guide di configurazione e note
assets/       # immagini e screenshot
```

## Configurazione

### 1. Configurare le variabili d'ambiente di n8n

Imposta queste variabili sul tuo server n8n (Settings → Environment variables oppure env del docker-compose):

| Variabile | Descrizione |
|---|---|
| `WSPAF_WP_SITE_URL` | URL base di WordPress (es. `https://example.com`) |
| `WSPAF_APPROVAL_EMAIL` | Indirizzo email che riceve le richieste di approvazione |
| `WSPAF_APPROVAL_NAME` | Nome visualizzato del destinatario dell'approvazione |
| `WSPAF_SENDER_EMAIL` | Indirizzo mittente usato per tutte le email del workflow |

### 2. Creare le credenziali n8n

Crea queste credenziali in n8n (Settings → Credentials):

| Nome credenziale | Tipo | Usata da |
|---|---|---|
| `OpenAI account` | OpenAI API | Generazione del messaggio AI |
| `SMTP Account` | SMTP | Email di approvazione e notifica |
| `X OAuth account` | X OAuth1 API | Upload dei media su Twitter |
| `X OAuth2 account` | X OAuth2 API | Creazione del tweet |

Vedi la sezione [Configurazione credenziali Twitter/X](#configurazione-credenziali-twitterx) per la configurazione completa dell'app sviluppatore X.

### 3. Configurare gli strumenti locali (solo per il deploy)

**Genera la chiave REST API di n8n:** nell'interfaccia n8n vai in Settings → API → Generate API Key. Copia la chiave: la vedrai una sola volta.

**Imposta le seguenti variabili d'ambiente a livello macchina** sul tuo ambiente di sviluppo:

| Variabile | Descrizione |
|---|---|
| `WSPAF_N8N_BASE_URL` | URL base di n8n (es. `https://n8n.example.com`) |
| `WSPAF_N8N_API_KEY` | Chiave REST API di n8n generata sopra |

Su **Windows** (esegui come Amministratore, poi riavvia il terminale):
```cmd
setx WSPAF_N8N_BASE_URL "https://n8n.example.com" /M
setx WSPAF_N8N_API_KEY your-api-key /M
```

Su **Linux / macOS** (aggiungi a `~/.bashrc` o `~/.zshrc`):
```bash
export WSPAF_N8N_BASE_URL="https://n8n.example.com"
export WSPAF_N8N_API_KEY=your-api-key
```

### 4. Creare il workflow in n8n per la prima volta

`deploy.ps1` aggiorna un workflow **esistente** in base al nome. Su un'istanza n8n nuova devi prima crearlo manualmente:

1. Nell'interfaccia n8n vai su **Workflows → New workflow**.
2. Rinominalo esattamente in: `WP Social Publisher Approval Flow`
3. Salvalo (può anche essere vuoto: lo script di deploy lo popolerà)

> Nei deploy successivi questo passaggio non serve.

### 5. Fare il deploy del workflow

Lo script di deploy richiede **PowerShell** (incluso in Windows; installa [PowerShell Core](https://github.com/PowerShell/PowerShell) su Linux/macOS).

```powershell
.\scripts\deploy.ps1
```

Lo script risolve gli ID delle credenziali dall'istanza n8n di destinazione, li inietta nel payload, invia una richiesta `PUT` e verifica che il workflow remoto rifletta lo stato atteso.

### 6. Configurare i domini consentiti nella credenziale `X OAuth account`

Dopo aver creato la credenziale `X OAuth account` (OAuth1), devi consentire i domini dell'API Twitter:

1. In n8n → Credentials → apri `X OAuth account`
2. Trova il campo **Allowed HTTP Request Domains**
3. Aggiungi: `api.twitter.com` e `upload.twitter.com`
4. Salva

Senza questo passaggio n8n bloccherà le richieste HTTP firmate verso questi domini.

### 7. Attivare il workflow

Nell'interfaccia n8n, apri il workflow e attivalo con l'interruttore **Active**. Lo `Schedule Trigger` verrà eseguito ogni giorno alle 06:00.

---

## Test

Per testare il flusso senza attendere l'esecuzione schedulata successiva:

1. Apri il workflow nell'interfaccia n8n.
2. Fai clic su **Manual Trigger → Execute step**: questo esegue l'intero flusso dal rilevamento dell'articolo fino all'email di approvazione.
3. Controlla la tua casella email e fai clic su **Pubblica** oppure **Non pubblicare**.
4. L'esecuzione riprenderà e completerà il ramo corrispondente.

Per testare i singoli nodi dopo l'approval gate (che usa `sendAndWait` e non può essere aggirato con "Execute step"):

1. Fai clic su `Has Image? (Twitter)`, `Post Tweet` o qualunque nodo a valle.
2. Aggiungi **Pin data** con un payload di esempio contenente `hasFeaturedImage`, `socialMessage`, `imageUrl`, `postUrl`, `titleText`.
3. Fai clic su **Execute step** su quel nodo: l'esecuzione partirà dal nodo con dati pinnati, saltando tutto ciò che sta a monte, incluso l'approval gate.

---

## Nodi attuali del workflow

### Flusso principale

| Nodo | Tipo | Cosa fa |
|---|---|---|
| `Manual Trigger` | Trigger | Avvia il workflow manualmente per i test. |
| `Schedule Trigger (Daily 06:00)` | Trigger | Avvia automaticamente il workflow una volta al giorno alle 06:00. |
| `Fetch WP Posts` | HTTP Request | Chiama la REST API di WordPress (`$env.WSPAF_WP_SITE_URL`) e recupera i 20 articoli pubblicati più recenti, includendo i dati `_embedded` per i media in evidenza. Entrambi i trigger sono collegati direttamente a questo nodo. |
| `Debug - Count fetched posts` | Code | Registra il numero di articoli restituiti e una breve anteprima dei primi elementi. |
| `Detect New Posts (date_gmt)` | Code | Mantiene solo gli articoli pubblicati nelle ultime 1500 minuti (25 ore) in base a `date_gmt`. Aggiunge `detectedAtUtc` a ogni item. Se trova più di un articolo, il workflow prosegue con più item e il percorso a valle viene eseguito una volta per ciascun articolo. |
| `Deduplicate via Data Store` | Remove Duplicates | Salta gli articoli il cui `id` WordPress è già stato visto in un'esecuzione precedente (storico persistente a livello workflow, fino a 10.000 elementi). |
| `Debug - Deduplicate summary` | Code | Registra quanti articoli sono stati rilevati, mantenuti e saltati come duplicati. |
| `Extract URL and Featured Image` | Code | Normalizza ogni articolo in campi puliti: `titleText`, `excerptText`, `postUrl`, `imageUrl`, `hasFeaturedImage`. Rimuove i tag HTML e decodifica le entità (incluse quelle numeriche come `&#8211;`) da titolo ed estratto. |
| `Generate AI Message (max 280, #n8n)` | `@n8n/n8n-nodes-langchain.openAi` v2.1 | Chiama OpenAI `gpt-4o-mini` tramite Responses API (credenziale `OpenAI account`). Le istruzioni di sistema impongono massimo 280 caratteri, hashtag `#n8n`, URL in fondo e lingua coerente con il titolo del post. Input: `titleText`, `excerptText`, `postUrl`. |
| `Validate AI Message` | Code | Garantisce che l'output AI rispetti i vincoli indipendentemente da ciò che ha restituito OpenAI. Inserisce `#n8n` se manca, tronca a 280 caratteri preservando URL e hashtag. Aggiunge `socialMessage`, `socialMessageLength`, `socialMessageValid` al payload. |
| `Debug - AI message` | Code | Registra il testo finale di `socialMessage`, la lunghezza e la validità per ogni articolo. Visibile nella scheda **Logs** del dettaglio esecuzione in n8n. |
| `Approval Gate (Email)` | `n8n-nodes-base.emailSend` v2.1 `sendAndWait` | Invia un'email HTML di approvazione da `$env.WSPAF_SENDER_EMAIL` a `$env.WSPAF_APPROVAL_EMAIL` con titolo del post, URL, eventuale link immagine e anteprima del messaggio social generato. Pulsanti: **Pubblica** (approva) / **Non pubblicare** (rifiuta). Attende fino a 24 ore; se non arriva risposta, l'esecuzione riprende automaticamente e viene trattata come rifiutata. Credenziale: `SMTP Account`. |
| `Approved?` | `n8n-nodes-base.if` v2.3 | Dirama direttamente in base a `$json.data.approved` dalla risposta di `sendAndWait`. Uscita 0 (true) → pubblica. Uscita 1 (false/timeout) → salta. |
| `Has Image? (Twitter)` | `n8n-nodes-base.if` v2.2 | Controlla `hasFeaturedImage` dal nodo a monte `Validate AI Message` (i dati del post devono essere letti esplicitamente perché `$json` dopo `sendAndWait` contiene solo la risposta di approvazione). True → percorso con immagine. False → direttamente `Post Tweet`. |
| `Fetch Image Binary` | HTTP Request | Scarica l'immagine in evidenza come dato binario per prepararla all'upload. |
| `Upload Media to Twitter` | HTTP Request | Invia il binario a `upload.twitter.com/1.1/media/upload.json` con OAuth1 (`X OAuth account`). Restituisce `media_id_string`. |
| `Post Tweet with Image` | `n8n-nodes-base.twitter` v2 | Pubblica il tweet usando il nodo nativo X con `X OAuth2 account`. Testo da `Validate AI Message`, ID media dal passaggio di upload. |
| `Post Tweet` | `n8n-nodes-base.twitter` v2 | Lo stesso nodo nativo X, senza allegato media. Usato quando il post non ha immagine in evidenza. |
| `Skip - Not Approved` | NoOp | Raggiunto quando l'approvazione viene rifiutata o scade il timeout di 24 ore. Nessuna azione eseguita. |
| `Notify - Published with Image` | `n8n-nodes-base.emailSend` v2.1 | Invia un'email di conferma dopo una pubblicazione riuscita su X con immagine. L'oggetto include stato esplicito e ID del post WordPress. |
| `Notify - Published without Image` | `n8n-nodes-base.emailSend` v2.1 | Invia un'email di conferma dopo una pubblicazione riuscita su X senza immagine. L'oggetto include stato esplicito e ID del post WordPress. |
| `Notify - Not Approved` | `n8n-nodes-base.emailSend` v2.1 | Invia un'email di notifica quando l'approvazione viene rifiutata o scade. L'oggetto include stato esplicito e ID del post WordPress. |

### Ramo di manutenzione (separato dal flusso principale)

| Nodo | Cosa fa |
|---|---|
| `Manual Trigger (Clear Dedupe History)` | Avvia un ramo di manutenzione indipendente. |
| `Clear Dedupe History` | Reimposta lo storico di deduplicazione a livello workflow (utile durante il debug per rielaborare post già visti). |
| `Debug - Clear dedupe history` | Registra un payload di conferma dopo il reset. |

---

## Configurazione credenziali Twitter/X

Questo workflow usa due credenziali X separate perché l'upload dei media e la creazione del tweet usano famiglie di API diverse.

**Credenziale OAuth1** (per l'upload media — API v1.1, piano gratuito):
1. Crea un account sviluppatore su [developer.twitter.com](https://developer.twitter.com) e crea una nuova App.
2. In **User authentication settings** configura:
   - Permessi app: **Read and Write**
   - Tipo di app: **Web App**
   - Callback URI: `https://<your-n8n-domain>/rest/oauth1-credential/callback`
   - Abilita **solo OAuth 1.0a**: abilitare contemporaneamente OAuth 2.0 causa un 403 durante l'autorizzazione.
3. Da **Keys and Tokens**, copia: API Key, API Secret Key, Access Token, Access Token Secret.
4. In n8n → Credentials → Add → **X OAuth1 API** → salva come `X OAuth account`.

**Credenziale OAuth2** (per la creazione del tweet — API v2, richiesta dal piano gratuito):
1. Nella stessa app X, abilita **OAuth 2.0** (puoi farlo dopo aver completato la configurazione OAuth1 sopra).
2. Imposta il callback URI richiesto da n8n: `https://<your-n8n-domain>/rest/oauth2-credential/callback`.
3. In n8n → Credentials → Add → **X OAuth2 API** → salva come `X OAuth2 account`.

**Perché due credenziali:** il piano gratuito dell'API X consente la creazione dei tweet solo tramite endpoint v2, che richiedono OAuth2. L'upload dei media è disponibile solo tramite v1.1, che richiede OAuth1. Il nodo nativo Twitter di n8n usa OAuth2; il nodo di upload media è una HTTP Request che usa direttamente OAuth1.

| Nodo | Tipo auth | Credenziale |
|---|---|---|
| `Upload Media to Twitter` | OAuth1 | `X OAuth account` |
| `Post Tweet with Image` | OAuth2 | `X OAuth2 account` |
| `Post Tweet` | OAuth2 | `X OAuth2 account` |

---

## Procedura di deploy

`scripts/deploy.ps1` è l'unico strumento di deploy in questo repository. Invia il workflow JSON locale a un workflow n8n esistente tramite REST API di n8n.

**Cosa fa, passo per passo:**

1. Legge `WSPAF_N8N_BASE_URL` e `WSPAF_N8N_API_KEY` dalle variabili d'ambiente a livello macchina.
2. Chiama `GET /api/v1/credentials` sull'istanza n8n di destinazione e risolve gli ID delle quattro credenziali richieste in base al nome (`OpenAI account`, `SMTP Account`, `X OAuth account`, `X OAuth2 account`).
3. Chiama `GET /api/v1/workflows` e trova il workflow remoto chiamato `WP Social Publisher Approval Flow`.
4. Carica da disco `workflows/active/wp-social-publisher-approval-flow.json`.
5. Inietta nel payload gli ID delle credenziali risolti nei nodi corrispondenti (gli ID delle credenziali dipendono dall'istanza e non devono mai essere hardcoded nel file sorgente).
6. Invia una richiesta `PUT /api/v1/workflows/{id}` per sovrascrivere il workflow remoto con quello locale.
7. Recupera di nuovo il workflow dal server e verifica che i nodi chiave siano presenti.

**Prerequisito:** il workflow deve già esistere sull'istanza n8n con il nome esatto indicato sopra (vedi [passaggio 4 della Configurazione](#4-creare-il-workflow-in-n8n-per-la-prima-volta)). Lo script aggiorna un workflow esistente: non lo crea.

---

## Integrazione server MCP

Questo progetto usa il server MCP a livello di istanza n8n per lo sviluppo assistito dall'AI. Configuralo in `.mcp.json` (non committato: contiene un token JWT). Claude Code si collega automaticamente all'avvio della sessione.

MCP viene usato per lo **sviluppo**: scoperta dei nodi, validazione e ispezione del workflow.  
La REST API (`scripts/deploy.ps1`) viene usata per il **deploy**.

| Strumento | Scopo |
|---|---|
| `search_nodes` / `get_node_types` | Risolvere ID esatti dei nodi e nomi dei parametri |
| `validate_workflow` | Validare il workflow prima del deploy |
| `get_workflow_details` | Leggere lo stato del workflow live sul server |
| `execute_workflow` / `get_execution` | Eseguire e ispezionare le esecuzioni per i test |

Vedi [DOC/n8n-mcp-claude-code-setup.md](DOC/n8n-mcp-claude-code-setup.md) per la procedura completa di configurazione.

---

## Riferimento variabili d'ambiente

| Variabile | Ambito | Descrizione |
|---|---|---|
| `WSPAF_N8N_BASE_URL` | Sviluppo locale / script | URL base di n8n per l'accesso REST API |
| `WSPAF_N8N_API_KEY` | Sviluppo locale / script | Chiave REST API di n8n |
| `WSPAF_WP_SITE_URL` | Runtime n8n | URL base di WordPress |
| `WSPAF_APPROVAL_EMAIL` | Runtime n8n | Indirizzo email del destinatario dell'approvazione |
| `WSPAF_APPROVAL_NAME` | Runtime n8n | Nome visualizzato del destinatario dell'approvazione |
| `WSPAF_SENDER_EMAIL` | Runtime n8n | Indirizzo mittente per tutte le email del workflow |

Le credenziali segrete e le integrazioni autenticate devono restare nelle credenziali n8n, mai nel workflow JSON o nei file del repository.
