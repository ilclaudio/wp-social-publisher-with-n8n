# Implementation Track

## 1) Obiettivo Progetto
Descrivi in 5-10 righe cosa deve fare il progetto a regime.

- Problema che risolve:
- Utenti destinatari:
- Risultato finale atteso:
- Metriche di successo (es. tempo risparmiato, errori ridotti, automazioni completate):

## 2) Contesto e Vincoli
Elenca i vincoli tecnici e organizzativi da rispettare.

- Stack/strumenti obbligatori:
- Vincoli infrastrutturali (server, rete, on-prem, ecc.):
- Vincoli di sicurezza/compliance:
- Vincoli operativi (finestre di deploy, backup, rollback):

## 3) Funzionalita (Backlog Testuale)
Inserisci le funzionalita in ordine logico, ognuna con questo formato.

### Funzionalita 1 - <Nome>
- Descrizione:
- Valore per l'utente:
- Input attesi:
- Output attesi:
- Dipendenze:
- Priorita: MVP | v1 | v2
- Stato: todo | in-progress | done
- Criteri di accettazione:
  1. 
  2. 
  3. 
- Test manuale minimo:
  1. 
  2. 
  3. 

### Funzionalita 2 - <Nome>
- Descrizione:
- Valore per l'utente:
- Input attesi:
- Output attesi:
- Dipendenze:
- Priorita: MVP | v1 | v2
- Stato: todo | in-progress | done
- Criteri di accettazione:
  1. 
  2. 
  3. 
- Test manuale minimo:
  1. 
  2. 
  3. 

## 4) Priorita e Rilasci
Raggruppa le funzionalita per milestone.

### MVP
- [ ] Funzionalita <id>
- [ ] Funzionalita <id>

### v1
- [ ] Funzionalita <id>
- [ ] Funzionalita <id>

### v2
- [ ] Funzionalita <id>
- [ ] Funzionalita <id>

## 5) Piano Step-by-Step di Implementazione
Spezza il lavoro in task piccoli, sequenziali e verificabili.

### Step 1 - <Titolo>
- Obiettivo:
- Attivita:
  1. 
  2. 
  3. 
- Definizione di completamento:
- Output atteso:
- Stato: todo | in-progress | done

### Step 2 - <Titolo>
- Obiettivo:
- Attivita:
  1. 
  2. 
  3. 
- Definizione di completamento:
- Output atteso:
- Stato: todo | in-progress | done

## 6) Rischi e Dipendenze

### Rischi
- Rischio:
  - Impatto:
  - Probabilita:
  - Mitigazione:

### Dipendenze esterne
- Dipendenza:
  - Tipo (tecnica/organizzativa/fornitore):
  - Blocco potenziale:
  - Piano B:

## 7) Regole Operative per l'Implementazione
Queste regole servono a usare questo file come traccia unica durante lo sviluppo.

- Ogni nuova richiesta di sviluppo deve riferirsi a una Funzionalita e a uno Step specifico.
- Prima di iniziare una modifica, imposta lo stato dello Step su in-progress.
- A fine implementazione e test, imposta lo stato su done.
- Se emerge nuovo scope, aggiungilo qui prima di implementarlo.
- Non inserire segreti nel repository o nei JSON dei workflow.

## 8) Log Decisioni
Tieni traccia delle decisioni tecniche rilevanti.

- Data:
- Decisione:
- Motivazione:
- Alternative considerate:
- Impatto:

## 9) Comandi Prompt Consigliati
Usa questi prompt per lavorare in modo coerente con la traccia.

1. "Implementa Funzionalita <id>, Step <id> in `AGENTS/IMPLEMENTATION_TRACK.md`."
2. "Aggiorna stato e criteri di accettazione della Funzionalita <id> dopo le modifiche."
3. "Esegui review dello Step <id> rispetto ai criteri di accettazione definiti."
4. "Proponi il prossimo Step minimo per avanzare verso MVP."
