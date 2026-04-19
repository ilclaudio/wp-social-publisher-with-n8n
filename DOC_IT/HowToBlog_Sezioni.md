# Scaletta articolo blog: come ho sviluppato questo progetto con AI, MCP e cartella AGENTS

Obiettivo dell'articolo:
raccontare la metodologia di sviluppo usata per realizzare il progetto, mettendo al centro la collaborazione con gli assistenti AI, l'uso del server MCP e soprattutto il ruolo della cartella `AGENTS` come struttura di contesto del progetto.

Lunghezza target: 700-900 parole. Tono divulgativo, concreto, in prima persona. Non tutorial tecnico: piu' un dietro le quinte del metodo di lavoro.

## Idea guida

L'articolo funziona meglio se non viene impostato come elenco di strumenti usati, ma come racconto di un metodo:
un progetto sviluppato con il supporto dell'AI, reso piu' solido da un contesto scritto bene, da istruzioni riutilizzabili e da un collegamento operativo verso n8n tramite MCP.

## Struttura consigliata

1. Introduzione - la parte interessante non e' solo il workflow
Aprire dicendo che il progetto in se' e' utile, ma il vero punto interessante e' come e' stato costruito. L'aggancio puo' essere questo: oggi non cambia solo cio' che si puo' automatizzare, ma anche il modo in cui si sviluppano questi progetti.

2. Il progetto in poche righe
Riassumere rapidamente il workflow: nuovi articoli WordPress, generazione del messaggio social, approvazione via email, pubblicazione su X solo dopo conferma. Questa sezione serve solo per dare al lettore il contesto minimo.

3. Sviluppare in collaborazione con l'AI, non delegare tutto all'AI
Spiegare che `ChatGPT Codex` e `Claude Code` non sono stati usati come generatori automatici di codice, ma come collaboratori operativi: lettura del repository, scrittura di file, revisione di scelte, chiarimento di errori, documentazione. Il messaggio da far passare e' che il valore non nasce dalla delega totale, ma dall'interazione continua tra persona, progetto e assistenti.

4. MCP e REST API: accesso operativo a n8n, ciascuno al momento giusto
Questa e' la sezione tecnica piu' forte. Spiegare in modo semplice che il server MCP ha dato agli assistenti un accesso strutturato all'ambiente reale: ricerca dei nodi, validazione, ispezione dei dettagli del workflow, analisi delle esecuzioni. In questo modo l'AI non lavorava su ipotesi generiche, ma su un contesto verificabile.
Subito dopo, introdurre il contrasto con la REST API: MCP serve durante lo sviluppo e l'ispezione, la REST API (`scripts/deploy.ps1`) serve nella fase di deploy e sincronizzazione del workflow sul server. Questo mostra che il metodo separa chiaramente osservazione, modifica e rilascio — tre momenti con strumenti diversi.

5. Il cuore del metodo: la cartella AGENTS
Questa deve essere la sezione piu' valorizzata dell'articolo. Raccontare che la cartella `AGENTS` non e' semplice documentazione di supporto, ma una vera interfaccia di lavoro per gli assistenti. Serve a evitare che ogni sessione riparta da zero e rende il progetto piu' coerente nel tempo.
Descrivere il meccanismo di session bootstrap: ogni volta che un assistente apre il progetto, legge i file in un ordine definito e ricostruisce il contesto prima di fare qualsiasi cosa. Questo rende il comportamento prevedibile e ripetibile, indipendentemente dall'assistente usato o da quanto tempo e' passato dall'ultima sessione.

6. Due tipi di file nella cartella AGENTS: direttive riutilizzabili e file descrittivi
Questa e' la distinzione piu' utile da comunicare. Presentarla in modo chiaro e concreto.

Le `direttive riutilizzabili` contengono regole operative stabili, valide anche oltre una singola sessione o un singolo progetto. Sono progettate per essere copiate o adattate su altri progetti senza modifiche sostanziali. Per esempio:
- `AGENTS/AI_BEHAVIOR.md` — come si comporta l'assistente, quali priorita' ha, come gestisce ambiguita' e sicurezza
- `AGENTS/GIT_WORKFLOW.md` — regole di branch, commit, PR e controllo dei dati sensibili prima di ogni push

I `file descrittivi` invece raccontano questo progetto specifico e il suo stato attuale. Cambiano nel tempo man mano che il progetto avanza. Per esempio:
- `AGENTS/PROJECT.md` — contesto, convenzioni, variabili d'ambiente, percorsi dei file, regole di deploy
- `AGENTS/IMPLEMENTATION_TRACK.md` — roadmap, stato di avanzamento di ogni feature, prossimi passi

Presentare questa distinzione come uno dei punti piu' utili del metodo: separare le regole permanenti dal contesto variabile rende gli assistenti piu' consistenti, riduce la confusione e permette di riusare le direttive su progetti futuri senza riscriverle da zero.

7. README e repository come fonte di verita', non come contorno
Spiegare che il `README.md`, i workflow salvati nel repository e i file di supporto non sono accessori, ma parte del sistema di lavoro. Questo rafforza l'idea che l'AI lavori bene quando trova un progetto leggibile, con confini chiari e una fonte di verita' condivisa.

8. Un esempio concreto
Inserire un breve esempio reale per rendere il metodo tangibile. Per esempio: quando e' stato necessario aggiungere il nodo di upload immagini su Twitter, l'assistente ha cercato il tipo di nodo via MCP, verificato i parametri esatti restituiti dall'istanza reale, e scritto la configurazione senza inventarsi nomi di campo. Il contesto scritto nella cartella AGENTS ha evitato di rispiegare le convenzioni del progetto (prefisso variabili, regole di deploy, credential naming) che erano gia' disponibili per iscritto.

9. Cosa cambia davvero nel modo di sviluppare
Chiudere con il beneficio concreto del metodo: meno tempo speso a ricostruire il contesto, meno ambiguita' tra una sessione e l'altra, piu' continuita' nel lavoro e maggiore verificabilita' delle scelte. Il punto finale non deve essere "l'AI fa tutto", ma "un progetto ben strutturato permette all'AI di essere davvero utile".

## Messaggio centrale da tenere in evidenza

La parte piu' originale non e' aver usato strumenti AI, ma averli inseriti in un progetto con una struttura di contesto esplicita.
Il server MCP rende possibile l'accesso operativo all'ambiente n8n.
La cartella `AGENTS` rende quel lavoro coerente, riutilizzabile e leggibile nel tempo.

## Cosa conviene evitare

- Non dedicare una sezione separata a ogni tool se il risultato e' solo un elenco.
- Non descrivere `AGENTS` come semplice documentazione interna: il suo valore e' metodologico, non archivistico.
- Non fare un tutorial tecnico su MCP o sulle API: qui conta il loro ruolo nel processo.
- Non chiudere con un elogio generico dell'AI: meglio chiudere sull'importanza del contesto scritto bene.
