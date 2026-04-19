# Quick WSL Guide: Installed Distros, Storage, Active Distro, and Cleanup

## Introduction: what WSL is and why to use it on Windows 11

**WSL** (Windows Subsystem for Linux) is a Windows feature that allows you to run a full Linux environment directly on Windows, without a separate virtual machine and without dual boot. With WSL you can open a Bash terminal, install packages with `apt`, run Python or Node.js scripts, use Git natively, and work with Linux-style command-line tools, all without leaving Windows.

The current version, **WSL 2**, is not just a simple system-call translation layer: it uses a real Linux kernel running inside a lightweight VM managed by Hyper-V. This makes it faster, more compatible, and able to run software that previously did not work (for example native Docker, systemd, and advanced networking tools).

**What it is for.** It is especially useful when you work with development stacks that originate on Linux: Node.js servers, Python, Docker, Ansible, cloud environments such as AWS/GCP/Azure CLI, toolchains such as make, gcc, or ffmpeg. On Windows these tools often behave differently or require adjustments; on WSL they work exactly as they do on a Linux server.

**How to install it on Windows 11.** Open PowerShell or Command Prompt as administrator and type:

```powershell
wsl --install
```

The command installs WSL 2 and automatically downloads Ubuntu as the default distro. After the restart, the Linux user is created on first launch. If you want a different distro, you can choose it with:

```powershell
wsl --install -d <DistroName>
```

To see the available distros: `wsl --list --online`.

**Why it is useful for developers on Windows.** WSL removes the need to maintain a separate VM or switch to Linux to work on server-side projects. It integrates with VS Code through the *Remote – WSL* extension, accesses the Windows filesystem through `/mnt/c/`, and is significantly faster than a traditional VM. You can have the best of both environments: Windows applications and a full Linux terminal on the same machine.

---

## Key distinction: WSL 2 vs distributions

It is easy to confuse `WSL 2` with a Linux distribution, but they are not the same thing.

**WSL 2** is the Windows platform/subsystem that makes it possible to run Linux. In practice it provides:

- integration with Windows;
- the Linux kernel used by WSL 2;
- the lightweight VM managed by the system;
- networking, Windows disk mounts, and distro startup mechanisms.

A **distribution**, on the other hand, is a specific Linux environment installed on top of WSL, for example `Ubuntu-20.04`, `Ubuntu-22.04`, or `docker-desktop`.

In other words:

- `WSL 2` is the shared "engine";
- the distribution is the single Linux system you use inside that engine.

### What distributions share under WSL 2

Distros installed under WSL 2 share some basic elements:

- Windows WSL technology;
- the Linux kernel provided by WSL 2;
- integration with the Windows filesystem, for example `/mnt/c`;
- the general runtime infrastructure managed by Windows.

### What they do not share

Each distro keeps its own separate environment:

- separate Linux filesystem;
- separate users and home directories;
- separate installed packages;
- separate configurations;
- its own services, processes, and disk space.

For example, if you install `git` or `node` in `Ubuntu-22.04`, you will not automatically find them in `Ubuntu-20.04`.

### How to read the `VERSION` column

In the `wsl -l -v` command, the `VERSION` column does not indicate the Ubuntu or distro version. It indicates whether that distro is using `WSL 1` or `WSL 2`.

So:

- `Ubuntu-20.04` is the distribution name;
- `VERSION 2` means that distribution is running on top of WSL 2.

---

## Goal

This guide collects the main commands to:

1. see how many WSL distros are installed;
2. see which ones are active and which one is the default;
3. estimate how much space they use;
4. compact the virtual disk to recover space;
5. change the default distro;
6. configure WSL with `.wslconfig` and enable systemd;
7. decide whether it makes sense to consolidate everything into a single newer Ubuntu distro.

---

## 1. See how many and which WSL distros are installed

From Windows PowerShell or `cmd.exe`:

```powershell
wsl -l -v
```

Typical output:

```text
  NAME            STATE    VERSION
* Ubuntu-20.04    Running  2
  Ubuntu-22.04    Stopped  2
  docker-desktop  Stopped  2
```

How to read it:

- `NAME`: distro name.
- `STATE`: whether it is running (`Running`) or stopped (`Stopped`).
- `VERSION`: WSL version used by the distro, almost always `2`.
- `*`: default distro. When you launch `wsl` without specifying anything else, this one starts.

To get only the list of names:

```powershell
wsl -l -q
```

### Note on `docker-desktop`

If `docker-desktop` appears in the list, it is not a normal working distro like `Ubuntu-20.04` or `Ubuntu-22.04`.

- `docker-desktop` is a technical WSL distro created and managed by Docker Desktop.
- It is used to run the Linux Docker engine on Windows through WSL 2.
- It does not replace your Ubuntu distro and should not be treated as your main development environment.
- Docker containers run in the Docker Desktop backend, not "inside" your Ubuntu distro as the main distro.
- Your Ubuntu distro remains the environment where you work with shell, Git, Node, Python, and project files.

In practice, `docker-desktop` may appear alongside the other distros in `wsl -l -v`, but it has a different role: it is Docker infrastructure, not a user distro to manage like the others.

---

## 2. See which distro is active right now

The best command remains:

```powershell
wsl -l -v
```

If a distro is `Running`, it means at least one WSL shell or process is using it.

To explicitly enter a specific distro:

```powershell
wsl -d Ubuntu-22.04
```

---

## 3. Change the default distro

To set a distro as the default:

```powershell
wsl --set-default Ubuntu-22.04
```

Or the short form:

```powershell
wsl -s Ubuntu-22.04
```

After the change, `wsl` without parameters will open that distro. Verify with:

```powershell
wsl -l -v
```

---

## 4. See how much space WSL distros use

### Practical method: inspect the `.vhdx` disk files

WSL 2 distros store their filesystem in a `.vhdx` virtual disk. The actual space used mainly depends on that file.

Open PowerShell and search for the virtual disks:

```powershell
Get-ChildItem "$env:LOCALAPPDATA\Packages" -Recurse -Filter ext4.vhdx -ErrorAction SilentlyContinue |
Select-Object FullName, @{Name="SizeGB";Expression={[math]::Round($_.Length / 1GB, 2)}}
```

For distros installed from the Microsoft Store, the file is often under:

```text
C:\Users\<user>\AppData\Local\Packages\<distro>\LocalState\ext4.vhdx
```

### Method from inside the distro

Inside each distro you can check how much space you are using at the Linux level:

```bash
df -h /
du -sh ~
```

However, this does not always match the size of the `.vhdx`, which may remain larger even after deleting files.

---

## 5. Compact the `.vhdx` virtual disk

The `.vhdx` file grows when you install packages or create files, but **it does not shrink automatically** when you delete them. To recover space you must compact it explicitly.

### Method 1: sparse (recommended, does not require full shutdown)

Enable sparse mode for the distro: WSL will automatically manage unused space.

```powershell
wsl --manage Ubuntu-22.04 --set-sparse true
```

### Method 2: Optimize-VHD (requires Windows Pro/Enterprise)

First stop the distro, then optimize the file:

```powershell
wsl --terminate Ubuntu-22.04
Optimize-VHD -Path "C:\Users\<user>\AppData\Local\Packages\<distro>\LocalState\ext4.vhdx" -Mode Full
```

### Method 3: diskpart (works on all Windows editions)

```powershell
wsl --shutdown
diskpart
```

Then inside `diskpart`:

```
select vdisk file="C:\Users\<user>\AppData\Local\Packages\<distro>\LocalState\ext4.vhdx"
attach vdisk readonly
compact vdisk
detach vdisk
exit
```

---

## 6. View the WSL home from Windows

From File Explorer you can open a WSL distro with a UNC path:

```text
\\wsl$\Ubuntu-22.04\home\<user>
```

or, in many installations:

```text
\\wsl.localhost\Ubuntu-22.04\home\<user>
```

If you want to open from Windows the Linux folder you are already in inside WSL:

```bash
explorer.exe .
```

### Practical note on paths

- Windows files inside WSL are mounted under `/mnt`, so `C:\` becomes `/mnt/c` and `D:\` becomes `/mnt/d`.
- For "pure" Linux files inside the distro, use `\\wsl$\...` or `\\wsl.localhost\...`.
- Avoid modifying internal distro files through paths under `AppData`: you can corrupt the WSL filesystem.

---

## 7. Stop one distro or all of WSL

To shut down a single distro:

```powershell
wsl --terminate Ubuntu-20.04
```

To shut down all distros and the WSL subsystem:

```powershell
wsl --shutdown
```

These commands do not uninstall anything: they only stop the processes.

---

## 8. Uninstall a distro you no longer need

To remove a distro:

```powershell
wsl --unregister Ubuntu-20.04
```

Warning: this command completely deletes the distro. You lose the filesystem, home, installed packages, and configurations. Use it only after a backup or migration.

Before proceeding, export the distro as a backup:

```powershell
wsl --export Ubuntu-20.04 C:\backup\Ubuntu-20.04.tar
```

To restore it later:

```powershell
wsl --import Ubuntu-20.04 C:\WSL\Ubuntu-20.04 C:\backup\Ubuntu-20.04.tar --version 2
```

---

## 9. Configure WSL: `.wslconfig` and systemd

### Limit RAM and CPU with `.wslconfig`

By default WSL 2 can use up to half of the RAM available on the system. If you work on machines with little memory, you can limit it by creating or editing the `%USERPROFILE%\.wslconfig` file (that is, `C:\Users\<user>\.wslconfig`):

```ini
[wsl2]
memory=4GB
processors=2
swap=2GB
```

Changes take effect after `wsl --shutdown`.

### Enable systemd

On Ubuntu 22.04 and later, you can enable **systemd** — required for tools such as `snapd`, native `dockerd`, and `systemctl`. Inside the distro, create or edit `/etc/wsl.conf`:

```ini
[boot]
systemd=true
```

Restart the distro with `wsl --terminate <DistroName>` and on reopening systemd will be active. Verify with:

```bash
systemctl --version
```

---

## 10. Is it worth keeping only one distro?

In most cases: **yes, it is**.

Keeping a single main distro, for example `Ubuntu-22.04`, brings these benefits:

- less disk space used;
- no duplication of packages, caches, toolchains, and configurations;
- a clear path for backup and restore;
- less risk of updating the wrong distro while you work.

### When it makes sense to keep multiple distros

Keep two or more distros only if you really need to:

- test software on different Ubuntu versions;
- isolate environments that are incompatible with each other;
- keep an old distro as a temporary fallback during a migration.

### Recommended strategy to consolidate without risk

1. Choose the distro to keep, for example `Ubuntu-22.04`, and set it as default:

```powershell
wsl --set-default Ubuntu-22.04
```

2. Verify that inside that distro you have the configurations you use:
   - user home, SSH keys, Git config;
   - `~/.codex/config.toml`;
   - installed runtimes and tools.

3. Export the old distro as a backup:

```powershell
wsl --export Ubuntu-20.04 C:\backup\Ubuntu-20.04.tar
```

4. Use only the new distro for a few days.

5. When you are sure everything works, remove the old one:

```powershell
wsl --unregister Ubuntu-20.04
```

In practice, one well-maintained distro is almost always better than three half-configured distros.

---

## 11. Cheat sheet

| Command | What it does |
|---|---|
| `wsl -l -v` | Lists all distros with state and WSL version |
| `wsl -l -q` | Lists only distro names |
| `wsl -d Ubuntu-22.04` | Opens a shell in the specified distro |
| `wsl --set-default Ubuntu-22.04` | Sets the default distro |
| `wsl --terminate Ubuntu-20.04` | Stops a single distro |
| `wsl --shutdown` | Stops all distros and the WSL subsystem |
| `wsl --export Ubuntu-20.04 C:\backup\Ubuntu-20.04.tar` | Exports the distro as a tar archive |
| `wsl --import Ubuntu-20.04 C:\WSL\Ubuntu-20.04 C:\backup\Ubuntu-20.04.tar --version 2` | Restores a distro from an archive |
| `wsl --unregister Ubuntu-20.04` | Completely uninstalls the distro |
| `wsl --manage Ubuntu-22.04 --set-sparse true` | Enables automatic compaction of the virtual disk |

To estimate the space used by WSL disks:

```powershell
Get-ChildItem "$env:LOCALAPPDATA\Packages" -Recurse -Filter ext4.vhdx -ErrorAction SilentlyContinue |
Select-Object FullName, @{Name="SizeGB";Expression={[math]::Round($_.Length / 1GB, 2)}}
```
