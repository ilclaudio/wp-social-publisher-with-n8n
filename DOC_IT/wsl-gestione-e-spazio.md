# Guida rapida WSL: distro installate, spazio, distro attiva e pulizia

## Introduzione: cos'è WSL e perché usarlo su Windows 11

**WSL** (Windows Subsystem for Linux) è una funzionalità di Windows che permette di eseguire un ambiente Linux completo direttamente su Windows, senza macchina virtuale separata e senza dual boot. Con WSL puoi aprire un terminale Bash, installare pacchetti con `apt`, eseguire script Python o Node.js, usare Git in modo nativo e lavorare con tool da riga di comando tipici del mondo Linux, tutto senza uscire da Windows.

La versione attuale, **WSL 2**, non è un semplice layer di traduzione delle chiamate di sistema: usa un vero kernel Linux che gira all'interno di una VM leggera gestita da Hyper-V. Questo lo rende più veloce, più compatibile e in grado di eseguire software che prima non funzionava (ad esempio Docker nativo, systemd, strumenti di rete avanzati).

**A cosa serve.** È utile soprattutto quando lavori con stack di sviluppo che nascono su Linux: server Node.js, Python, Docker, Ansible, ambienti cloud come AWS/GCP/Azure CLI, toolchain come make, gcc o ffmpeg. Su Windows questi tool spesso hanno comportamenti diversi o richiedono adattamenti; su WSL funzionano esattamente come su un server Linux.

**Come si installa su Windows 11.** Apri PowerShell o il Prompt dei comandi come amministratore e digita:

```powershell
wsl --install
```

Il comando installa WSL 2 e scarica automaticamente Ubuntu come distro predefinita. Dopo il riavvio, al primo avvio si crea l'utente Linux. Se vuoi una distro diversa, puoi sceglierla con:

```powershell
wsl --install -d <NomeDistro>
```

Per vedere le distro disponibili: `wsl --list --online`.

**Perché è utile per chi sviluppa su Windows.** WSL elimina la necessità di mantenere una VM separata o di passare a Linux per lavorare su progetti server-side. Si integra con VS Code tramite l'estensione *Remote – WSL*, accede al filesystem Windows tramite `/mnt/c/`, ed è significativamente più veloce di una VM tradizionale. Puoi avere il meglio dei due ambienti: le applicazioni Windows e un terminale Linux completo, sulla stessa macchina.

---

## Distinzione chiave: WSL 2 vs distribuzioni

E facile confondere `WSL 2` con una distribuzione Linux, ma non sono la stessa cosa.

**WSL 2** e la piattaforma/sottosistema di Windows che rende possibile eseguire Linux. In pratica fornisce:

- l'integrazione con Windows;
- il kernel Linux usato da WSL 2;
- la VM leggera gestita dal sistema;
- i meccanismi di rete, mount dei dischi Windows e avvio delle distro.

Una **distribuzione** invece e un ambiente Linux specifico installato sopra WSL, per esempio `Ubuntu-20.04`, `Ubuntu-22.04` o `docker-desktop`.

In altre parole:

- `WSL 2` e il "motore" comune;
- la distribuzione e il singolo sistema Linux che usi dentro quel motore.

### Cosa condividono le distribuzioni sotto WSL 2

Le distro installate in WSL 2 condividono alcuni elementi di base:

- la tecnologia WSL di Windows;
- il kernel Linux fornito da WSL 2;
- l'integrazione con il filesystem Windows, per esempio `/mnt/c`;
- l'infrastruttura generale di esecuzione gestita da Windows.

### Cosa non condividono

Ogni distro mantiene invece il proprio ambiente separato:

- filesystem Linux separato;
- utenti e home directory separate;
- pacchetti installati separati;
- configurazioni separate;
- servizi, processi e spazio disco propri.

Per esempio, se installi `git` o `node` in `Ubuntu-22.04`, non li ritrovi automaticamente in `Ubuntu-20.04`.

### Come leggere la colonna `VERSION`

Nel comando `wsl -l -v`, la colonna `VERSION` non indica la versione di Ubuntu o della distro. Indica se quella distro sta usando `WSL 1` o `WSL 2`.

Quindi:

- `Ubuntu-20.04` e il nome della distribuzione;
- `VERSION 2` significa che quella distribuzione sta girando sopra WSL 2.

---

## Obiettivo

Questa guida raccoglie i comandi principali per:

1. vedere quante distro WSL sono installate;
2. vedere quali sono attive e quale è quella predefinita;
3. stimare quanto spazio occupano;
4. compattare il disco virtuale per recuperare spazio;
5. cambiare la distro predefinita;
6. configurare WSL con `.wslconfig` e abilitare systemd;
7. decidere se conviene consolidare tutto su una sola Ubuntu più recente.

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
- `STATE`: se è in esecuzione (`Running`) o ferma (`Stopped`).
- `VERSION`: versione WSL usata dalla distro, quasi sempre `2`.
- `*`: distro predefinita. Quando lanci `wsl` senza specificare altro, parte questa.

Per avere solo l'elenco dei nomi:

```powershell
wsl -l -q
```

### Nota su `docker-desktop`

Se nell'elenco compare `docker-desktop`, non e una tua normale distro di lavoro come `Ubuntu-20.04` o `Ubuntu-22.04`.

- `docker-desktop` e una distro WSL tecnica creata e gestita da Docker Desktop.
- Serve a far girare il motore Docker Linux su Windows tramite WSL 2.
- Non sostituisce la tua Ubuntu e non va trattata come ambiente principale di sviluppo.
- I container Docker girano nel backend di Docker Desktop, non "dentro" la tua distro Ubuntu come distro principale.
- La tua distro Ubuntu resta invece l'ambiente in cui lavori tu con shell, Git, Node, Python e file di progetto.

In pratica, `docker-desktop` puo comparire accanto alle altre distro in `wsl -l -v`, ma ha un ruolo diverso: e infrastruttura di Docker, non una distro utente da amministrare come le altre.

---

## 2. Vedere quale distro è attiva adesso

Il comando migliore resta:

```powershell
wsl -l -v
```

Se una distro è `Running`, significa che almeno una shell o processo WSL la sta usando.

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

Dopo il cambio, `wsl` senza parametri aprirà quella distro. Verifica con:

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

Per le distro installate da Microsoft Store, il file è spesso sotto:

```text
C:\Users\<utente>\AppData\Local\Packages\<distro>\LocalState\ext4.vhdx
```

### Metodo interno alla distro

Dentro ogni distro puoi controllare quanto spazio stai usando a livello Linux:

```bash
df -h /
du -sh ~
```

Questo però non sempre coincide con la dimensione del `.vhdx`, che può restare più grande anche dopo aver cancellato file.

---

## 5. Compattare il disco virtuale `.vhdx`

Il file `.vhdx` cresce quando installi pacchetti o crei file, ma **non si riduce automaticamente** quando li cancelli. Per recuperare spazio devi compattarlo esplicitamente.

### Metodo 1: sparse (consigliato, non richiede shutdown completo)

Abilita la modalità sparse per la distro: WSL gestirà automaticamente lo spazio non usato.

```powershell
wsl --manage Ubuntu-22.04 --set-sparse true
```

### Metodo 2: Optimize-VHD (richiede Windows Pro/Enterprise)

Prima ferma la distro, poi ottimizza il file:

```powershell
wsl --terminate Ubuntu-22.04
Optimize-VHD -Path "C:\Users\<utente>\AppData\Local\Packages\<distro>\LocalState\ext4.vhdx" -Mode Full
```

### Metodo 3: diskpart (funziona su tutte le edizioni di Windows)

```powershell
wsl --shutdown
diskpart
```

Poi dentro `diskpart`:

```
select vdisk file="C:\Users\<utente>\AppData\Local\Packages\<distro>\LocalState\ext4.vhdx"
attach vdisk readonly
compact vdisk
detach vdisk
exit
```

---

## 6. Vedere la home WSL da Windows

Da Esplora File puoi aprire una distro WSL con un percorso UNC:

```text
\\wsl$\Ubuntu-22.04\home\<utente>
```

oppure in molte installazioni:

```text
\\wsl.localhost\Ubuntu-22.04\home\<utente>
```

Se vuoi aprire da Windows la cartella Linux in cui ti trovi già dentro WSL:

```bash
explorer.exe .
```

### Nota pratica sui percorsi

- I file Windows dentro WSL sono montati sotto `/mnt`, quindi `C:\` diventa `/mnt/c` e `D:\` diventa `/mnt/d`.
- Per i file Linux "puri" della distro usa `\\wsl$\...` oppure `\\wsl.localhost\...`.
- Evita di modificare i file interni della distro passando da percorsi sotto `AppData`: puoi corrompere il filesystem WSL.

---

## 7. Fermare una distro o tutto WSL

Per chiudere una singola distro:

```powershell
wsl --terminate Ubuntu-20.04
```

Per spegnere tutte le distro e il sottosistema WSL:

```powershell
wsl --shutdown
```

Questi comandi non disinstallano nulla: fermano solo i processi.

---

## 8. Disinstallare una distro che non ti serve più

Per rimuovere una distro:

```powershell
wsl --unregister Ubuntu-20.04
```

Attenzione: il comando cancella completamente la distro. Perdi filesystem, home, pacchetti installati e configurazioni. Usalo solo dopo backup o migrazione.

Prima di procedere, esporta la distro come backup:

```powershell
wsl --export Ubuntu-20.04 C:\backup\Ubuntu-20.04.tar
```

Per ripristinarla in futuro:

```powershell
wsl --import Ubuntu-20.04 C:\WSL\Ubuntu-20.04 C:\backup\Ubuntu-20.04.tar --version 2
```

---

## 9. Configurare WSL: `.wslconfig` e systemd

### Limitare RAM e CPU con `.wslconfig`

Per impostazione predefinita WSL 2 può usare fino alla metà della RAM disponibile sul sistema. Se lavori su macchine con poca memoria, puoi limitarlo creando o modificando il file `%USERPROFILE%\.wslconfig` (cioè `C:\Users\<utente>\.wslconfig`):

```ini
[wsl2]
memory=4GB
processors=2
swap=2GB
```

Le modifiche diventano effettive dopo `wsl --shutdown`.

### Abilitare systemd

Su Ubuntu 22.04 e versioni successive, puoi abilitare **systemd** — necessario per strumenti come `snapd`, `dockerd` nativo, `systemctl`. Dentro la distro, crea o modifica `/etc/wsl.conf`:

```ini
[boot]
systemd=true
```

Riavvia la distro con `wsl --terminate <NomeDistro>` e alla riapertura systemd sarà attivo. Verifica con:

```bash
systemctl --version
```

---

## 10. Conviene tenere una sola distro?

Nella maggior parte dei casi: **sì, conviene**.

Tenere una sola distro principale, per esempio `Ubuntu-22.04`, porta questi vantaggi:

- meno spazio occupato su disco;
- nessuna duplicazione di pacchetti, cache, toolchain e configurazioni;
- percorso chiaro per backup e restore;
- meno rischio di aggiornare la distro sbagliata mentre lavori.

### Quando ha senso tenere più distro

Mantieni due o più distro solo se ti serve davvero:

- testare software su versioni Ubuntu diverse;
- isolare ambienti incompatibili tra loro;
- conservare una distro vecchia come fallback temporaneo durante una migrazione.

### Strategia consigliata per consolidare senza rischi

1. Scegli la distro da tenere, ad esempio `Ubuntu-22.04`, e impostala come predefinita:

```powershell
wsl --set-default Ubuntu-22.04
```

2. Verifica che dentro quella distro ci siano le configurazioni che usi:
   - home utente, chiavi SSH, config Git;
   - `~/.codex/config.toml`;
   - runtime e tool installati.

3. Esporta la vecchia distro come backup:

```powershell
wsl --export Ubuntu-20.04 C:\backup\Ubuntu-20.04.tar
```

4. Usa per qualche giorno solo la distro nuova.

5. Quando sei sicuro che tutto funzioni, rimuovi la vecchia:

```powershell
wsl --unregister Ubuntu-20.04
```

In pratica, una sola distro ben tenuta è quasi sempre meglio di tre distro mezze configurate.

---

## 11. Cheat sheet

| Comando | Cosa fa |
|---|---|
| `wsl -l -v` | Elenca tutte le distro con stato e versione WSL |
| `wsl -l -q` | Elenca solo i nomi delle distro |
| `wsl -d Ubuntu-22.04` | Apre una shell nella distro specificata |
| `wsl --set-default Ubuntu-22.04` | Imposta la distro predefinita |
| `wsl --terminate Ubuntu-20.04` | Ferma una singola distro |
| `wsl --shutdown` | Ferma tutte le distro e il sottosistema WSL |
| `wsl --export Ubuntu-20.04 C:\backup\Ubuntu-20.04.tar` | Esporta la distro come archivio tar |
| `wsl --import Ubuntu-20.04 C:\WSL\Ubuntu-20.04 C:\backup\Ubuntu-20.04.tar --version 2` | Ripristina una distro da archivio |
| `wsl --unregister Ubuntu-20.04` | Disinstalla completamente la distro |
| `wsl --manage Ubuntu-22.04 --set-sparse true` | Abilita la compattazione automatica del disco virtuale |

Per stimare lo spazio occupato dai dischi WSL:

```powershell
Get-ChildItem "$env:LOCALAPPDATA\Packages" -Recurse -Filter ext4.vhdx -ErrorAction SilentlyContinue |
Select-Object FullName, @{Name="SizeGB";Expression={[math]::Round($_.Length / 1GB, 2)}}
```
