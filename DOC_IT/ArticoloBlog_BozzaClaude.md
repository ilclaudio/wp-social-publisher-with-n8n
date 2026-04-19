# Automatizzare la pubblicazione sui social con n8n: un caso reale

Ogni volta che pubblico un articolo sul mio blog, so già cosa succederà: aprirò una nuova scheda, andrò su X, scriverò qualcosa di frettoloso come "nuovo articolo, dai un'occhiata", incollerò il link e pubblicherò. Oppure me ne dimenticherò del tutto per tre giorni.

Non è un problema complesso. È solo un passaggio ripetitivo, prevedibile, che richiede attenzione nel momento sbagliato — quando ho appena finito di scrivere e l'ultima cosa che voglio fare è ricominciare da un'altra finestra.

È esattamente il tipo di problema che si presta all'automazione.

---

## Cos'è n8n

n8n è uno strumento open source per costruire workflow di automazione in modo visuale. Collega servizi diversi — WordPress, email, OpenAI, X, Slack e molti altri — con una logica definita da chi lo configura. Non è un servizio SaaS con prezzi per operazione: si installa sul proprio server e si controlla completamente.

---

## Come funziona il flusso

Ho costruito un workflow in n8n che fa esattamente quello che facevo a mano, ma in modo automatico e coerente.

Ogni mattina alle 6, n8n si sveglia e interroga le API di WordPress per recuperare gli articoli pubblicati nelle ultime 24 ore. Se non ce ne sono, si ferma. Se ne trova uno nuovo, lo prende e lo prepara: estrae il titolo, il testo introduttivo, l'URL e l'immagine in evidenza, se presente.

A questo punto ha tutto quello che serve per passare al passo successivo.

[*qui inserire screenshot del canvas n8n*]

---

## Il ruolo dell'intelligenza artificiale

Con i dati dell'articolo in mano, n8n chiama OpenAI e gli chiede di scrivere un testo per X/Twitter. Non un testo qualsiasi: deve essere nella stessa lingua dell'articolo, includere l'hashtag `#n8n`, terminare con l'URL e stare entro 280 caratteri.

Il workflow verifica poi che questi vincoli siano rispettati — indipendentemente da quello che ha risposto OpenAI. Se l'hashtag manca, lo aggiunge. Se il testo è troppo lungo, lo accorcia preservando URL e hashtag.

L'AI in questo flusso non è il protagonista: è uno strumento come gli altri, inserito in un processo con regole precise. n8n lo orchestra, non gli delega il controllo.

---

## Il punto che cambia tutto: l'approvazione umana

Qui sta la parte che trovo più interessante di questo workflow.

Dopo aver generato il testo, n8n non pubblica subito. Invia un'email con tutti i dettagli: il titolo dell'articolo, il link, l'eventuale immagine e il testo proposto per il tweet. In fondo ci sono due pulsanti: **Pubblica** e **Non pubblicare**.

Il workflow si ferma e aspetta. Fino a 24 ore.

Se clicco su Pubblica, n8n riprende l'esecuzione: carica l'immagine su X se disponibile, pubblica il tweet e mi manda una email di conferma. Se clicco su Non pubblicare, o se non rispondo entro 24 ore, il post viene saltato senza nessuna azione.

Questo rovescia un'idea comune sull'automazione: che automatizzare voglia dire rinunciare al controllo. In realtà si può costruire un flusso che fa tutto il lavoro ripetitivo — recuperare, elaborare, preparare — e si ferma esattamente dove serve una decisione umana.

---

## Il risultato in pratica

Da quando uso questo workflow, ogni nuovo articolo viene valutato per la pubblicazione su X senza che io debba ricordarmi di farlo. Ricevo un'email, leggo il testo proposto, decido in due secondi. Se va bene, clicco Pubblica. Se il testo non mi convince, clicco Non pubblicare e lo scrivo a mano quando voglio.

Zero dimenticanze. Zero schede aperte nel momento sbagliato. Un processo uguale ogni volta, che non dipende dal mio umore o dalla mia memoria.

---

## Una domanda per chiudere

Questo workflow risolve un problema piccolo, ma il meccanismo è lo stesso che si applica a processi molto più complessi: raccogliere dati, elaborarli, coinvolgere strumenti diversi, fermarsi per un'approvazione, notificare il risultato.

Qual è il processo che ti porta via più tempo ogni settimana, non perché sia difficile, ma perché richiede di ricordarsi di farlo?
