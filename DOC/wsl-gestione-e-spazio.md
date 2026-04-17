# Guida rapida WSL: distro installate, spazio, distro attiva e pulizia

## Obiettivo

Questa guida raccoglie i comandi principali per:

1. vedere quante distro WSL sono installate;
2. vedere quali sono attive e quale e' quella predefinita;
3. stimare quanto spazio occupano;
4. cambiare la distro predefinita;
5. decidere se conviene consolidare tutto su una sola Ubuntu piu' recente.

---

## 1. Vedere quante e quali distro WSL sono installate

Da Windows PowerShell o `cmd.exe`:

```powershell
wsl -l -v
```

Output tipico:

```text
  NAME            STATE    VERSION
* Ubuntu-20.04    Running  2
  Ubuntu-22.04    Stopped  2
  docker-desktop  Stopped  2
```

Come leggerlo:

- `NAME`: nome della distro.
- `STATE`: se e' in esecuzione (`Running`) o ferma (`Stopped`).
- `VERSION`: versione WSL usata dalla distro, quasi sempre `2`.
- `*`: distro predefinita. Quando lanci `wsl` senza specificare altro, parte questa.

Per avere solo l'elenco dei nomi:

```powershell
wsl -l -q
```

---

## 2. Vedere quale distro e' attiva adesso

Il comando migliore resta:

```powershell
wsl -l -v
```

Se una distro e' `Running`, significa che almeno una shell o processo WSL la sta usando.

Per entrare esplicitamente in una distro specifica:

```powershell
wsl -d Ubuntu-22.04
```

---

## 3. Cambiare la distro predefinita

Per impostare una distro come predefinita:

```powershell
wsl --set-default Ubuntu-22.04
```

Oppure forma breve:

```powershell
wsl -s Ubuntu-22.04
```

Dopo il cambio, `wsl` senza parametri aprira' quella distro.

Verifica:

```powershell
wsl -l -v
```

---

## 4. Vedere quanto spazio occupano le distro WSL

### Metodo pratico: vedere i file disco `.vhdx`

Le distro WSL 2 salvano il filesystem in un disco virtuale `.vhdx`. Lo spazio occupato reale dipende soprattutto da quel file.

Apri PowerShell e cerca i dischi virtuali:

```powershell
Get-ChildItem "$env:LOCALAPPDATA\Packages" -Recurse -Filter ext4.vhdx -ErrorAction SilentlyContinue |
Select-Object FullName, @{Name="SizeGB";Expression={[math]::Round($_.Length / 1GB, 2)}}
```

Questo ti mostra:

- il percorso del file disco della distro;
- la dimensione occupata sul disco Windows.

### Dove si trovano spesso

Per le distro installate da Microsoft Store, il file e' spesso sotto:

```text
C:\Users\<utente>\AppData\Local\Packages\<distro>\LocalState\ext4.vhdx
```

### Metodo interno alla distro: quanto pesa il filesystem Linux

Dentro ogni distro puoi anche controllare quanto spazio stai usando a livello Linux:

```bash
df -h /
du -sh ~
```

Questo pero' non sempre coincide con la dimensione del `.vhdx`, che puo' restare piu' grande anche dopo aver cancellato file.

---

## 5. Vedere la home WSL da Windows

Da Esplora File puoi aprire una distro WSL con un percorso UNC come:

```text
\\wsl$\Ubuntu-22.04\home\<utente>
```

oppure in molte installazioni:

```text
\\wsl.localhost\Ubuntu-22.04\home\<utente>
```

Esempio:

```text
\\wsl$\Ubuntu-20.04\home\claudio\.codex
```

Se vuoi aprire da Windows la cartella Linux in cui ti trovi gia' dentro WSL, dal terminale puoi usare:

```bash
explorer.exe .
```

### Nota pratica sui percorsi

- I file Windows dentro WSL sono montati sotto `/mnt`, quindi `C:\` diventa `/mnt/c` e `D:\` diventa `/mnt/d`.
- Se il progetto sta in `/mnt/c/...`, da Windows lo stesso percorso e' semplicemente `C:\...`.
- Per i file Linux "puri" della distro, usa `\\wsl$\...` oppure `\\wsl.localhost\...`.
- Evita di modificare i file interni della distro passando da percorsi sotto `AppData`, perche' puoi corrompere o compromettere il filesystem WSL.

---

## 6. Fermare una distro o tutto WSL

Per chiudere una singola distro:

```powershell
wsl --terminate Ubuntu-20.04
```

Per spegnere tutte le distro e il sottosistema WSL:

```powershell
wsl --shutdown
```

Questo non disinstalla nulla: ferma solo i processi.

---

## 7. Disinstallare una distro che non ti serve piu'

Per rimuovere una distro:

```powershell
wsl --unregister Ubuntu-20.04
```

Attenzione:

- il comando cancella completamente la distro;
- perdi filesystem, home, pacchetti installati e configurazioni;
- va usato solo dopo backup o migrazione.

Se vuoi essere prudente, prima esporta:

```powershell
wsl --export Ubuntu-20.04 C:\backup\Ubuntu-20.04.tar
```

Se un domani ti serve ripristinarla:

```powershell
wsl --import Ubuntu-20.04 C:\WSL\Ubuntu-20.04 C:\backup\Ubuntu-20.04.tar --version 2
```

---

## 8. Conviene tenere una sola Ubuntu recente per risparmiare spazio?

Nella maggior parte dei casi: **si', conviene**.

Tenere una sola distro principale, per esempio `Ubuntu-22.04`, di solito porta questi vantaggi:

- meno spazio occupato su disco;
- meno duplicazioni di pacchetti, cache, toolchain e config;
- meno confusione su dove si trovano `~/.codex`, SSH keys, config Git, Node, Python e altri strumenti;
- meno rischio di aggiornare una distro mentre stai lavorando in un'altra;
- percorso piu' chiaro per backup e restore.

### Quando ha senso tenere piu' distro

Ha senso mantenere due o piu' distro solo se ti serve davvero:

- testare software su versioni Ubuntu diverse;
- isolare ambienti incompatibili tra loro;
- conservare una vecchia distro come fallback temporaneo durante una migrazione.

Se non hai una necessita' precisa, una sola Ubuntu recente e' quasi sempre la scelta migliore.

---

## 9. Strategia consigliata per ridurre spazio senza rischi

Ordine consigliato:

1. Scegli la distro che vuoi tenere, ad esempio `Ubuntu-22.04`.
2. Impostala come predefinita:

```powershell
wsl --set-default Ubuntu-22.04
```

3. Verifica che dentro quella distro ci siano davvero i file e le configurazioni che usi:
   - home utente;
   - chiavi SSH;
   - `~/.codex/config.toml`;
   - config Git;
   - runtime e tool installati.
4. Esporta la vecchia distro come backup:

```powershell
wsl --export Ubuntu-20.04 C:\backup\Ubuntu-20.04.tar
```

5. Usa per qualche giorno solo la distro nuova.
6. Quando sei sicuro che tutto funzioni, rimuovi la vecchia:

```powershell
wsl --unregister Ubuntu-20.04
```

Questa e' la strada piu' ordinata per recuperare spazio senza fare pulizia aggressiva troppo presto.

---

## 10. Raccomandazione pratica

Se oggi hai piu' Ubuntu WSL e non ti servono per test distinti, ti conviene:

1. consolidare tutto su `Ubuntu-22.04` o su un'altra distro recente;
2. impostarla come default;
3. migrare dentro quella home le configurazioni importanti;
4. tenere un export `.tar` delle distro vecchie;
5. disinstallare le distro non piu' necessarie.

In pratica, una sola distro ben tenuta e' quasi sempre meglio di tre distro mezze configurate.

---

## 11. Comandi essenziali da ricordare

```powershell
wsl -l -v
wsl -l -q
wsl -d Ubuntu-22.04
wsl --set-default Ubuntu-22.04
wsl --terminate Ubuntu-20.04
wsl --shutdown
wsl --export Ubuntu-20.04 C:\backup\Ubuntu-20.04.tar
wsl --unregister Ubuntu-20.04
```

Per stimare lo spazio occupato dai dischi WSL:

```powershell
Get-ChildItem "$env:LOCALAPPDATA\Packages" -Recurse -Filter ext4.vhdx -ErrorAction SilentlyContinue |
Select-Object FullName, @{Name="SizeGB";Expression={[math]::Round($_.Length / 1GB, 2)}}
```
