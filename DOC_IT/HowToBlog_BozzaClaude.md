# Come ho costruito un workflow n8n con l'AI — e perché il metodo conta più degli strumenti

*Bozza — aprile 2026*

---

Il progetto in sé non è particolarmente originale: rilevo i nuovi articoli pubblicati su WordPress, genero un messaggio social con l'AI, lo mando in approvazione via email, e pubblico su X solo dopo conferma esplicita. Un workflow di automazione come tanti. La parte interessante non è cosa automatizza, ma come è stato costruito.

Negli ultimi mesi ho iniziato a usare assistenti AI — Claude Code e Codex in particolare — in modo diverso da come avrei immaginato un anno fa. Non come generatori di codice da controllare a posteriori, ma come collaboratori operativi con accesso reale al progetto. Questo cambia abbastanza le cose.

---

## Il progetto in due righe

Ogni giorno alle 06:00 (o su trigger manuale), il workflow interroga la REST API di WordPress, estrae gli ultimi post, chiede a OpenAI di generare un messaggio entro 280 caratteri con l'hashtag `#n8n`, e manda tutto a me via email con due pulsanti: *Pubblica* o *Non pubblicare*. Se approvo, il workflow pubblica il tweet — con immagine se disponibile, senza altrimenti — e mi manda una conferma. Se non rispondo entro 24 ore, il post viene saltato.

Il flusso funziona. Ma non è lì che ho imparato qualcosa di nuovo.

---

## Sviluppare con l'AI, non delegare all'AI

C'è una differenza tra usare un assistente AI per generare codice e usarlo come collaboratore di progetto. Nel primo caso gli dai un prompt e valuti l'output. Nel secondo caso lui legge il repository, capisce le convenzioni, fa domande, rivede le scelte con te.

Per farlo funzionare in questo secondo modo, ho dovuto costruire una struttura di contesto esplicita. Un progetto leggibile per un assistente non è solo un progetto ben documentato per un umano — è un progetto con confini chiari, regole scritte in modo operativo, e una fonte di verità unica.

---

## MCP durante lo sviluppo, REST API per il deploy

Una delle scelte più utili è stata tenere separati i due momenti: ispezione/sviluppo e deploy.

Il server MCP di n8n dà agli assistenti accesso strutturato all'istanza reale: ricerca dei nodi disponibili, lettura dei parametri esatti, validazione del workflow, analisi delle esecuzioni. Quando ho dovuto aggiungere il nodo di upload immagini su Twitter, l'assistente ha chiamato `search_nodes`, ottenuto il tipo di nodo corretto, verificato i parametri restituiti dall'istanza, e scritto la configurazione senza inventarsi nomi di campo. Senza MCP avrebbe lavorato su ipotesi.

Per il deploy uso invece uno script PowerShell (`deploy.ps1`) che chiama la REST API di n8n: risolve le credenziali, inietta gli ID corretti nel payload, aggiorna il workflow in place e verifica il risultato. MCP non tocca il deploy — quella responsabilità resta su uno strumento deterministico che posso ispezionare e versionare.

Tre momenti, tre strumenti: MCP per osservare, editor/assistente per modificare, script REST per rilasciare.

---

## La cartella AGENTS: contesto scritto, non documentazione interna

Questa è la parte del metodo che mi ha sorpreso di più per il suo impatto pratico.

Ho creato una cartella `AGENTS/` con pochi file di testo. Non sono manuali. Sono istruzioni operative che gli assistenti leggono all'inizio di ogni sessione, in un ordine definito, prima di fare qualsiasi cosa. Il risultato è che ogni sessione riparte da un contesto ricostruito, non da zero.

Dentro ci sono due tipi di file con ruoli molto diversi.

**Direttive riutilizzabili**: regole stabili che non dipendono da questo specifico progetto. `AI_BEHAVIOR.md` descrive come l'assistente deve comportarsi — priorità, gestione dell'ambiguità, sicurezza. `GIT_WORKFLOW.md` definisce le regole di branch, commit e cosa non deve mai finire in un push. Questi file posso copiarli su qualsiasi progetto futuro senza modificarli.

**File descrittivi**: raccontano questo progetto nel suo stato attuale. `PROJECT.md` contiene il contesto operativo — variabili d'ambiente, convenzioni di naming, percorsi dei file, regole di deploy, credential naming. `IMPLEMENTATION_TRACK.md` tiene traccia della roadmap, di cosa è già fatto, e del prossimo passo suggerito. Questi cambiano man mano che il progetto avanza.

La distinzione è semplice ma produce un effetto concreto: le regole operative rimangono consistenti tra sessioni e tra assistenti diversi. Il contesto variabile non inquina le regole stabili. E quando tra una sessione e l'altra cambio qualcosa — un nuovo nodo, una nuova variabile — aggiorno solo il file giusto.

---

## Un esempio: il nodo di upload immagini

Quando ho aggiunto la gestione delle immagini nel tweet, l'assistente ha dovuto capire che X usa due API diverse per media upload (v1.1 con OAuth1) e creazione del tweet (v2 con OAuth2). Ha cercato i nodi via MCP, ha letto le convenzioni di credential naming da `PROJECT.md` — dove stava già scritto come si chiamano le credenziali nel progetto — e ha scritto la configurazione senza che io dovessi rispiegare nulla. Ha fatto una domanda sola: se preferivo gestire l'upload con il nodo HTTP generico o con un nodo dedicato. Ho risposto, e ha implementato.

Questo tipo di interazione diventa fluido solo se il progetto è strutturato per supportarla.

---

## Cosa cambia davvero

Meno tempo a ricostruire il contesto. Meno ambiguità tra una sessione e l'altra. Meno correzioni a valle di errori evitabili.

Non ho delegato il progetto all'AI. Ho costruito un progetto in cui l'AI può essere davvero utile — perché trova le regole già scritte, il contesto già presente, e i confini già definiti. Il workflow è il risultato. Il metodo è la parte che porterei su qualsiasi progetto futuro.

---

*Il repository è pubblico: [github.com/ilclaudio/wp-social-publisher-with-n8n](https://github.com/ilclaudio/wp-social-publisher-with-n8n)*
