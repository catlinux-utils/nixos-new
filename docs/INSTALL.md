# Installation Guide

Complete disk preparation, installation, and post-install steps for this flake.

## Scripts Overview

| Script                      | Purpose                                                                                          |
| --------------------------- | ------------------------------------------------------------------------------------------------ |
| `scripts/nixos-disk`        | Interactive or flag-driven disk partitioning + formatting (LUKS + Btrfs/ext4/xfs)                |
| `scripts/nixos-mount`       | Mount prepared disk with all subvolumes for `nixos-install`; `--umount` unmounts and closes LUKS |
| `scripts/nixos-format-part` | Format selected existing partitions per-partition (FS, encryption, subvolumes)                   |
| `scripts/nixos-copy-repo`   | Copy this repo onto the target before reboot (`~/github/nixos` of the host's `cfg.user.name`)    |

---

## Quick Start (Interactive — Full End-to-End)

The interactive scripts pick the disk themselves — `nixos-disk` and
`nixos-format-part -i` prompt for it, `nixos-mount` auto-detects the disk
carrying `cryptroot`. No drive names needed.

### Option A: New Disk (partition + format)

```bash
# 0.
cd ~/github/nixos
# 1. Boot installer ISO or live Linux (as root)
sudo ./scripts/nixos-disk
# → prompts for: disk, encryption, filesystems, layout, sizes

# 2. Mount everything (auto-detects the disk)
sudo ./scripts/nixos-mount

# 3. Generate hardware config INTO THE REPO (tracked, host-specific)
#    Run from repo root (on target or via SSH); sudo — the btrfs probe needs
#    root, the redirect keeps the file owned by the live-session user:
sudo nixos-generate-config --show-hardware-config > hosts/desktop/hardware-configuration.nix

# 4. Install (root: nixos-install lays down the target's system closure)
sudo nixos-install --flake .#desktop --root /mnt

# 5. Copy the repo onto the target (user read from hosts/desktop's cfg.user.name)
sudo ./scripts/nixos-copy-repo desktop

# 6. Reboot into the new system
reboot
```

### Option B: Existing Partitions (format in place)

```bash
# 1. Boot installer ISO or live Linux (as root)
# Format selected partitions interactively (auto-detects the disk, prompts
# per-partition):
sudo ./scripts/nixos-format-part -i
# Or non-interactive:
# sudo ./scripts/nixos-format-part -p ESP=/dev/disk/by-id/<disk-id>-part1 -p cryptroot=/dev/disk/by-id/<disk-id>-part2 \
#   -f ESP=vfat -f cryptroot=btrfs -e ESP=no -e cryptroot=yes \
#   -l cryptroot=cryptroot -s cryptroot="@ @home @snapshots @log @nix" -m cryptroot=/mnt -y

# 2. Mount everything (auto-detects the disk)
sudo ./scripts/nixos-mount

# 3. Generate hardware config INTO THE REPO (tracked, host-specific)
sudo nixos-generate-config --show-hardware-config \
  > hosts/desktop/hardware-configuration.nix

# 4. Install (root: nixos-install lays down the target's system closure)
sudo nixos-install --flake .#desktop --root /mnt

# 5. Copy the repo onto the target (user read from hosts/desktop's cfg.user.name)
sudo ./scripts/nixos-copy-repo desktop

# 6. Reboot into the new system
reboot
```

---

### Post-Install: On the booted target machine, clone repo & rebuild

```bash
# With the installer ISO flow (or nixos-copy-repo step) the repo is already
# at ~/github/nixos — and the first activation turns it into a git repo with
# origin set (cfg.git.remote), so commit/push works right away.
# Otherwise clone it there:
git clone git@github.com:catlinux-utils/nixos-new.git ~/github/nixos
cd ~/github/nixos

# First rebuild — dry-run, then switch (nh reads cfg.nh.flakeDir = ~/github/nixos)
nh os switch --dry
nh os switch

# (Optional) Home Manager only
nh home switch
```

**Notes:**

- The generated `fileSystems` + LUKS initrd entries reflect the layout `scripts/nixos-disk`/`nixos-mount` create (mounts resolve via `/dev/mapper/cryptroot` and disk UUIDs — machine-independent).
- The `wsl` host doesn't need `hardware-configuration.nix` — NixOS-WSL owns boot and the filesystem.
- Set `cfg.user.initialHashedPassword` in the host config for first login; otherwise the account is locked until you run `passwd` from a root shell.

---

## Non-Interactive (CI / Scripted)

Flag-driven `nixos-disk` / `nixos-format-part` still take an explicit disk —
destructive formatting shouldn't auto-guess the target. Find the stable path
first (whole-disk entries only):

```bash
lsblk -dno NAME,SIZE,MODEL,TRAN,TYPE
ls -l /dev/disk/by-id/ | grep -v part-
```

### Desktop: single encrypted root, btrfs, swap partition

```bash
sudo ./scripts/nixos-disk \
  --encrypt-root yes --encrypt-home no --encrypt-swap yes \
  --fs-root btrfs --fs-home btrfs --fs-boot vfat \
  --swap-size 8G --boot-size 1G \
  /dev/disk/by-id/<disk-id>

sudo ./scripts/nixos-mount
sudo nixos-install --flake .#desktop --root /mnt
```

### Laptop: separate encrypted /home

```bash
sudo ./scripts/nixos-disk \
  --encrypt-root yes --encrypt-home yes --encrypt-swap yes \
  --fs-root btrfs --fs-home btrfs --fs-boot vfat \
  --root-size 50G --home-size 200G \
  /dev/disk/by-id/<disk-id>

sudo ./scripts/nixos-mount
sudo nixos-install --flake .#laptop --root /mnt
```

### Server: root + separate data partition

```bash
sudo ./scripts/nixos-disk --layout server /dev/disk/by-id/<disk-id>

sudo ./scripts/nixos-mount
sudo nixos-install --flake .#server --root /mnt
```

### Existing Partitions (non-interactive format-part)

```bash
sudo ./scripts/nixos-format-part \
  -p ESP=/dev/disk/by-id/<disk-id>-part1 -p cryptroot=/dev/disk/by-id/<disk-id>-part2 \
  -f ESP=vfat -f cryptroot=btrfs \
  -e ESP=no -e cryptroot=yes \
  -l cryptroot=cryptroot \
  -s cryptroot="@ @home @snapshots @log @nix" \
  -m cryptroot=/mnt \
  -y

sudo ./scripts/nixos-mount
sudo nixos-install --flake .#desktop --root /mnt
```

---

## Partition Layouts Created

| Layout             | Partitions                                | Subvolumes                                                                                                    |
| ------------------ | ----------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| **auto** (default) | ESP (1G) + cryptroot (rest) [+ cryptswap] | `@`, `@home`, `@snapshots`, `@log`, `@nix`                                                                    |
| **manual**         | You choose sizes                          | Per your selection                                                                                            |
| **server**         | ESP + cryptroot (100G) + cryptdata (rest) | root: `@` `@home` `@snapshots` `@log` `@nix`; data: `docker`, `containers`, `syncthing`, `backups`, `libvirt` |

All LUKS2, labeled (`ESP`, `cryptroot`, `crypthome`, `cryptdata`, `cryptswap`) for auto-detection.

---

## Manual Partition Formatting (Existing Partitions) — Reference

If partitions already exist and you want to format them individually:

### Interactive

```bash
sudo ./scripts/nixos-format-part -i
```

### Non-interactive

```bash
sudo ./scripts/nixos-format-part \
  -p ESP=/dev/disk/by-id/<disk-id>-part1 -p cryptroot=/dev/disk/by-id/<disk-id>-part2 \
  -f ESP=vfat -f cryptroot=btrfs \
  -e ESP=no -e cryptroot=yes \
  -l cryptroot=cryptroot \
  -s cryptroot="@ @home @snapshots @log @nix" \
  -m cryptroot=/mnt \
  -y
```

See `nixos-format-part --help` for all options.

---

## Hardware Configuration — Generate & Pull Into Repo

After mounting the target system at `/mnt`, generate the hardware config **into the repo** so it's tracked and host-specific:

```bash
# From repo root (on the target machine or via SSH):
sudo nixos-generate-config --show-hardware-config \
  > hosts/desktop/hardware-configuration.nix
```

This writes/overwrites `hosts/desktop/hardware-configuration.nix` with the detected hardware, including the `fileSystems` + LUKS initrd entries for the mounted layout. `--show-hardware-config` prints to stdout and the redirect happens in your own shell, so the file stays owned by the live-session user.

`sudo` is required: the tool probes every btrfs mount under `/mnt` with `btrfs subvolume show`, which needs root — without it the command dies with `Failed to retrieve subvolume info for /` (the `/` is actually `/mnt`; upstream [nixpkgs#417803](https://github.com/NixOS/nixpkgs/issues/417803)). The probe runs on every btrfs mount.

**Commit it later, from the booted host** (the live session's repo copy is git-cleaned — no `.git` — so `git commit` can't run there). The generated file survives the install via `scripts/nixos-copy-repo`; on the host, `cfg.git.remote` makes the first activation turn the working copy into a git repo with `origin` set, so `git add hosts/<host>/hardware-configuration.nix && git commit && git push` just works (identity: `cfg.home.git`).

Repeat for each host (`laptop`, `server`). The `wsl` host doesn't need one — NixOS-WSL owns boot and the filesystem.

---

## Post-Install: Copy Repo to Host & First Rebuild

After `nixos-install` completes and you reboot into the new system, the flake lives at `~/github/nixos` (`cfg.nh.flakeDir` on desktop/laptop/server) — `scripts/nixos-copy-repo` (quick-start step 5) put it there; on other flows, clone it as your user:

```bash
# On the target machine, as your user (no sudo — it's your home dir):

# 1. Skip if the repo is already at ~/github/nixos (installer-ISO flow);
#    otherwise clone it (adjust URL/branch):
git clone git@github.com:catlinux-utils/nixos-new.git ~/github/nixos

# 2. First rebuild — dry-run to verify, then switch
cd ~/github/nixos
nh os switch --dry
nh os switch

# 3. (Optional) Home Manager only
nh home switch
```

**If you set `cfg.user.initialHashedPassword` in the host config** (required for first login — see PLAN Phase 2), you can log in as your user immediately. Otherwise the account is locked until you set a password via `passwd` from a root shell.

**WSL host** — different flow: the flake lives on the WSL Linux side (`cfg.nh.flakeDir` = `/home/cat/nixos` in `hosts/wsl/default.nix` — never on `/mnt/c`, 9p is too slow for nix), and you run `wsl.exe -d NixOS` to enter.

---

## Encryption Notes

- **LUKS2** with AES-NI: ~0% performance overhead on modern CPUs
- **TRIM/DISCARD** passes through: `fstrim.timer` enabled via `cfg.storage.enable`
- **TPM2 auto-unlock**: Configure via `cfg.boot.secureBoot.measuredBoot.autoCryptenroll` (needs Secure Boot + TPM2)
- **Swap**: Encrypted partition or swapfile on Btrfs (hibernation needs `resume=` kernel param)

---

## Filesystem Choice

| FS        | Pros                                                    | Cons                            |
| --------- | ------------------------------------------------------- | ------------------------------- |
| **btrfs** | Snapshots, compression (zstd), subvolumes, send/receive | Slightly more complex           |
| **ext4**  | Simple, universal, fast                                 | No native snapshots/compression |
| **xfs**   | Scalable, fast for large files                          | No shrink, no native snapshots  |

Btrfs + zstd recommended for desktop/laptop (compresses game assets, shaders, configs).
